#!/bin/bash

# Prevent prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# --- Blue/Green Container Deployment Configuration ---
# First instance is always GREEN and ACTIVE 
GREEN_CONTAINER_NAME="app-be-green"
GREEN_CONTAINER_PORT="3000" # Port for Green container (initially active)

# Update the package list and install necessary packages
sudo apt-get update -y
sudo apt-get install -y ruby wget

# Install the CodeDeploy agent for pipeline
cd /tmp
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto > /dev/null

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Clean up installation files
rm -rf aws awscliv2.zip install

# Get AWS Region from instance metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
ECR_REPOSITORY=$(aws ssm get-parameter --name "/app/deployment/ecr_repository_name" --query "Parameter.Value" --output text)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

sudo service codedeploy-agent start
sudo systemctl enable codedeploy-agent

# Install Docker without prompts
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt-get install -y curl
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install NGINX without prompts
sudo apt-get install -y nginx

# Stop NGINX before configuration changes
sudo systemctl stop nginx

# Remove all existing config files to start fresh
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx/sites-available/default

# Create the NGINX configuration file for the reverse proxy
sudo tee /etc/nginx/sites-available/reverse-proxy.conf > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$GREEN_CONTAINER_PORT; # Initial Proxy to Green Port
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create symbolic link to enable the new configuration
sudo ln -sf /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/

# Start NGINX with new configuration
sudo systemctl start nginx
sudo systemctl enable nginx

# Install Redis
sudo apt-get install -y redis-server

# Update Redis configuration to bind to all interfaces
sudo sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf

# Configure Redis to start on boot
sudo systemctl enable redis-server

# Start the Redis service
sudo systemctl start redis-server
sudo mkdir -p /var/log/app-be
sudo touch /var/log/app-be/combined.log
sudo chmod 666 /var/log/app-be/combined.log
# Install CloudWatch Agent (official Amazon .deb for Ubuntu x86-64)
CWA_DEB_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
cd /tmp
wget -q $CWA_DEB_URL -O amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
rm -f amazon-cloudwatch-agent.deb

# Wait for agent install to complete and directory to exist
for i in {1..10}; do
  if [ -d /opt/aws/amazon-cloudwatch-agent/etc ]; then break; fi
  sleep 1
done

# Create CloudWatch Agent config for CPU, memory, and Docker logs
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}",
      "InstanceId": "\${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app-be/combined.log",
            "log_group_name": "/aws/ec2/app-be",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

sudo systemctl restart amazon-cloudwatch-agent

# Create docker-compose.yaml file with parameter store values - Using CONTAINER_NAME env variable
sudo tee docker-compose.yaml > /dev/null <<EOF
services:
  app-be:
    image: ${ECR_REPOSITORY}:latest
    container_name: ${GREEN_CONTAINER_NAME} # Dynamic container name from environment variable
    restart: always
    network_mode: host
    environment:
      - PORT=${GREEN_CONTAINER_PORT}
EOF

# Log in to ECR using fetched region
aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REPOSITORY}

# Run Docker Compose in detached mode
sudo docker-compose -p $GREEN_CONTAINER_NAME up -d

# ===== COMMON VARIABLES =====
HOSTNAME=$(hostname)

if [[ "$AWS_REGION" == "us-east-1" ]]; then
  FLUENT_BIT_S3_BUCKET="app-logs-dev"
else
  FLUENT_BIT_S3_BUCKET="app-logs-prod"
fi

# ===== FIND OBSERVABILITY EIP =====
OBSERVABILITY_PRIVATE_IP=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters "Name=tag:Observability,Values=true" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PrivateIpAddress" \
  --output text)

if [[ -z "$OBSERVABILITY_PRIVATE_IP" ]]; then
  echo "❌ Observability private IP not found"; exit 1
fi

LOKI_URL="http://$OBSERVABILITY_PRIVATE_IP:3100/loki/api/v1/push"
LOG_PATH="/var/log/app-be/combined.log"

# ===== NODE EXPORTER =====
NODE_EXPORTER_VERSION="1.8.1"
sudo useradd -rs /bin/false node_exporter || true
cd /tmp && curl -LO https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar xvf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo cp node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/

sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# ===== PROMTAIL =====
cd /opt
sudo curl -LO https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
sudo unzip -o promtail-linux-amd64.zip
sudo chmod +x promtail-linux-amd64
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

sudo tee /etc/promtail-config.yaml >/dev/null <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: /tmp/promtail-positions.yaml
clients:
  - url: $LOKI_URL
scrape_configs:
  - job_name: app-backend
    static_configs:
      - targets: [localhost]
        labels:
          job: app-backend
          project: app-backend
          instance: $INSTANCE_ID
          __path__: $LOG_PATH
EOF

sudo tee /etc/systemd/system/promtail.service >/dev/null <<EOF
[Unit]
Description=Promtail Log Shipper
After=network.target
[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail-config.yaml
Restart=always
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now promtail

# ===== FLUENT BIT (Official) =====
# Install Fluent Bit using official installation script
curl -L https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

# Verify installation
/opt/fluent-bit/bin/fluent-bit --version

# Create buffer directory
sudo mkdir -p /tmp/fluent-bit-buffer

# Get AWS credentials from parameter store
FLUENT_BIT_CREDENTIALS=$(aws ssm get-parameter --name "/app/fluent_bit_credentials" --with-decryption --query "Parameter.Value" --output text)

# Create environment file with AWS credentials
# Parse and dump the credentials directly from parameter store
echo "${FLUENT_BIT_CREDENTIALS}" | sudo tee /etc/fluent-bit/fluent-bit.env >/dev/null

# Backup default config and create new one
sudo mv /etc/fluent-bit/fluent-bit.conf /etc/fluent-bit/fluent-bit.conf.default 2>/dev/null || true

sudo tee /etc/fluent-bit/fluent-bit.conf >/dev/null <<EOF
[SERVICE]
    Flush        5
    Daemon       off
    Log_Level    info
    Parsers_File /etc/fluent-bit/parsers.conf

[INPUT]
    Name              tail
    Path              /var/log/app-be/combined.log
    Parser            json
    Tag               app.api
    Refresh_Interval  5
    DB                /var/log/flb-app.db
    Skip_Long_Lines   On

[FILTER]
    Name    record_modifier
    Match   *
    Record  hostname \${HOSTNAME}
    Record  environment dev
    Record  service api

[OUTPUT]
    Name                  s3
    Match                 *
    bucket                ${FLUENT_BIT_S3_BUCKET}
    region                ${AWS_REGION}
    use_put_object        On
    compression           gzip
    s3_key_format         /operational/year=%Y/month=%m/day=%d/api-\$UUID.json.gz
    total_file_size       20M
    upload_timeout        10s
    store_dir             /tmp/fluent-bit-buffer
EOF

# Create systemd service file
sudo tee /etc/systemd/system/fluent-bit.service >/dev/null <<EOF
[Unit]
Description=Fluent Bit
Documentation=https://docs.fluentbit.io
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/fluent-bit/fluent-bit.env
ExecStart=/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=fluent-bit
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable fluent-bit
sudo systemctl start fluent-bit

# Verify it's working
sudo systemctl status fluent-bit
sudo journalctl -u fluent-bit -n 50

