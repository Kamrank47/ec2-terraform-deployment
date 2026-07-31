#!/bin/bash
# Monitoring Stack Setup Script - Optimized for EC2 User Data
#set -euo pipefail

MONITORING_DIR="/opt/monitoring"
DATA_DIR="$MONITORING_DIR/data"
CONFIG_DIR="$MONITORING_DIR/config"

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --silent)
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
[[ -z "$AWS_REGION" ]] && { echo "Failed to detect AWS region"; exit 1; }

ENVIRONMENT="${ENVIRONMENT}"
monitoring_domain="${monitoring_domain}"
log_info() { echo "[INFO] $1"; }
error_exit() { echo "[ERROR] $1"; exit 1; }

# Install Docker & Docker Compose for Ubuntu
install_docker() {
    log_info "Installing Docker for Ubuntu..."
    
    # Update package index
    sudo apt-get update -y

    # upgrade packages
    sudo apt-get upgrade -y
    
    # Install required packages
    sudo apt-get install -y curl ca-certificates gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker ubuntu

    # update docker group
    newgrp docker

    # install network package 
    sudo apt install net-tools
    log_info "Installing Docker Compose standalone..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_info "Docker and Docker Compose installed successfully"
}

# Install Nginx and Certbot for Ubuntu
install_nginx_certbot() {
    log_info "Installing Nginx and Certbot for Ubuntu..."
    
    # Update package index
    sudo apt-get update -y
    
    # Install nginx and certbot
    sudo apt-get install -y nginx certbot python3-certbot-nginx
    
    # Start and enable nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Check if nginx is running
    if sudo systemctl is-active --quiet nginx; then
        log_info "Nginx installed and started successfully"
    else
        error_exit "Failed to start Nginx"
    fi
    
    log_info "Nginx and Certbot installed successfully"
}

# Configure Nginx for Grafana
configure_nginx() {
    log_info "Configuring Nginx for domain: ${monitoring_domain}"
    
    # Create nginx configuration file
    sudo tee /etc/nginx/sites-available/${monitoring_domain}.conf > /dev/null <<EOF
# Nginx configuration for proxying Grafana
server {
    listen 80;
    server_name ${monitoring_domain};
    
    # Location block to handle all requests and proxy them to Grafana
    location / {
        # Proxy requests to the Grafana instance
        proxy_pass http://localhost:3000;
        
        # Set necessary proxy headers to ensure Grafana works correctly behind Nginx
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Increase buffer sizes for large responses
        proxy_buffers 8 16k;
        proxy_buffer_size 32k;
        
        # Set timeouts for proxy connections
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        
        # Disable Nginx buffering to allow Grafana to stream responses
        proxy_buffering off;
    }
    
    # Error pages
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

    # Create sites-enabled directory if it doesn't exist (for systems that don't have it)
    sudo mkdir -p /etc/nginx/sites-enabled
    
    # Create symbolic link to enable the site
    sudo ln -sf /etc/nginx/sites-available/${monitoring_domain}.conf /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    sudo nginx -t
    if [ $? -ne 0 ]; then
        error_exit "Nginx configuration test failed"
    fi
    
    # Reload nginx
    sudo systemctl reload nginx
    
    log_info "Nginx configuration created and enabled"
}

# Setup SSL certificate with Let's Encrypt
setup_ssl_certificate() {
    log_info "Setting up SSL certificate for ${monitoring_domain}"
    
    # Wait for Grafana to be ready
    log_info "Waiting for Grafana to be ready..."
    sleep 30
    
    # Check if Grafana is responding
    for i in {1..10}; do
        if curl -f http://localhost:3000 &>/dev/null; then
            log_info "Grafana is ready"
            break
        fi
        log_info "Waiting for Grafana... (attempt $i/10)"
        sleep 10
    done
    
    # Obtain SSL certificate
    log_info "Obtaining SSL certificate..."
    sudo certbot --nginx -d ${monitoring_domain} --non-interactive --agree-tos --email admin@example.com --redirect
    
    if [ $? -eq 0 ]; then
        log_info "SSL certificate obtained and configured successfully"
        
        # Setup automatic renewal
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
        
        log_info "SSL certificate auto-renewal configured"
    else
        log_info "SSL certificate setup failed, continuing with HTTP configuration"
    fi
}

# Create directories
create_directories() {
    log_info "Creating directories..."
    sudo mkdir -p $DATA_DIR/{prometheus,grafana,loki} $CONFIG_DIR/{prometheus,grafana,loki}
    sudo chown -R $USER:$USER $MONITORING_DIR
    sudo chmod -R 775 $DATA_DIR/grafana && sudo mkdir -p $DATA_DIR/grafana/plugins && sudo chmod -R 775 $DATA_DIR/grafana/plugins
    sudo chown -R 65534:65534 $DATA_DIR/prometheus && sudo chown -R 10001:10001 $DATA_DIR/loki
}

# Create configs
create_configs() {
    log_info "Creating configurations..."
    
    # Prometheus config
    cat > $CONFIG_DIR/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files: ["alerts.yml"]
alerting:
  alertmanagers:
    - static_configs: [targets: []]
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels: {environment: '$ENVIRONMENT'}
  - job_name: 'ec2-node-exporter'
    ec2_sd_configs:
      - region: $AWS_REGION
        port: 9100
        filters:
          - name: "tag:Environment"
            values: ['$ENVIRONMENT']
          - name: tag:Region
            values: ['$AWS_REGION']
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
      - source_labels: [__meta_ec2_tag_Environment]
        target_label: environment
      - source_labels: [__meta_ec2_private_ip]
        target_label: private_ip
      - source_labels: [__meta_ec2_public_ip]
        target_label: public_ip
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id
  - job_name: 'app-backend-metrics'
    ec2_sd_configs:
      - region: $AWS_REGION
        port: 80
        filters:
          - name: tag:Environment
            values: ['$ENVIRONMENT']
          - name: tag:Region
            values: ['$AWS_REGION']
    metrics_path: /api/metrics
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_tag_Environment]
        target_label: environment
      - source_labels: [__meta_ec2_tag_Project_Name]
        target_label: project
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id
EOF

    # Prometheus alerts
    cat > $CONFIG_DIR/prometheus/alerts.yml <<EOF
groups:
  - name: basic-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels: {severity: warning}
        annotations: {summary: "High error rate detected", description: "Error rate is above 10% for 5 minutes"}
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels: {severity: warning}
        annotations: {summary: "High memory usage", description: "Memory usage is above 90%"}
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels: {severity: warning}
        annotations: {summary: "High CPU usage", description: "CPU usage is above 80%"}
EOF

    # Loki config
    cat > $CONFIG_DIR/loki/loki.yml <<EOF
auth_enabled: false
server: {http_listen_port: 3100}
common:
  path_prefix: /loki
  storage: {filesystem: {chunks_directory: /loki/chunks, rules_directory: /loki/rules}}
  replication_factor: 1
  ring: {kvstore: {store: inmemory}}
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index: {prefix: index_, period: 24h}
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  retention_period: 720h
chunk_store_config: {max_look_back_period: 0s}
table_manager: {retention_deletes_enabled: true, retention_period: 720h}
ruler:
  storage: {type: local, local: {directory: /loki/rules}}
  rule_path: /loki/rules
  alertmanager_url: http://localhost:9093
  ring: {kvstore: {store: inmemory}}
  enable_api: true
EOF

    # Grafana config
    cat > $CONFIG_DIR/grafana/grafana.ini <<EOF
[server]
protocol = http
http_port = 3000
domain = ${monitoring_domain}
[database]
type = sqlite3
path = /var/lib/grafana/grafana.db
[security]
admin_user = admin
# NOTE: placeholder values for demo purposes only - source these from SSM/Secrets Manager
# and use a generated password in any real deployment.
admin_password = app-monitoring-${ENVIRONMENT}
secret_key = app-grafana-secret-key-${ENVIRONMENT}
[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer
[auth.anonymous]
enabled = false
[log]
mode = console
level = info
[panels]
disable_sanitize_html = false
[alerting]
enabled = true
EOF

    # Grafana datasources
    mkdir -p $CONFIG_DIR/grafana/provisioning/{datasources,dashboards}
    cat > $CONFIG_DIR/grafana/provisioning/datasources/datasources.yml <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
EOF

    # Grafana dashboards
    cat > $CONFIG_DIR/grafana/provisioning/dashboards/dashboards.yml <<EOF
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options: {path: /var/lib/grafana/dashboards}
EOF
}

# Create Docker Compose
create_docker_compose() {
    log_info "Creating Docker Compose..."
    cat > $MONITORING_DIR/docker-compose.yml <<EOF
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    restart: unless-stopped
    ports: ["9090:9090"]
    volumes:
      - ./config/prometheus:/etc/prometheus:ro
      - ./data/prometheus:/prometheus
      - ~/.aws:/root/.aws:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    environment: [AWS_REGION=$AWS_REGION, AWS_SDK_LOAD_CONFIG=true]
    user: "root:root"
    networks: [monitoring]
  grafana:
    image: grafana/grafana:10.0.0
    container_name: grafana
    restart: unless-stopped
    ports: ["3000:3000"]
    volumes:
      - ./config/grafana:/etc/grafana
      - ./data/grafana:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=app-monitoring-${ENVIRONMENT}
      - GF_PATHS_DATA=/var/lib/grafana
    user: "0:0"
    networks: [monitoring]
  loki:
    image: grafana/loki:2.9.0
    container_name: loki
    restart: unless-stopped
    ports: ["3100:3100"]
    volumes:
      - ./config/loki:/etc/loki:ro
      - ./data/loki:/loki
    command: -config.file=/etc/loki/loki.yml
    user: "10001:10001"
    networks: [monitoring]
networks:
  monitoring: {driver: bridge}
volumes:
  prometheus_data:
  grafana_data:
  loki_data:
EOF
}

# Create systemd service
create_systemd_service() {
    log_info "Creating systemd service..."
    sudo tee /etc/systemd/system/app-monitoring.service > /dev/null <<EOF
[Unit]
Description=App Monitoring Stack
Requires=docker.service
After=docker.service
[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$MONITORING_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=$USER
Group=$USER
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload && sudo systemctl enable app-monitoring
}

# Main execution
main() {
    log_info "Starting App Monitoring Stack installation for environment: $ENVIRONMENT"
    log_info "Monitoring domain: ${monitoring_domain}"
    log_info "AWS Region: $AWS_REGION"
    
    # Install dependencies
    install_docker
    install_nginx_certbot
    
    # Setup monitoring stack
    create_directories
    create_configs
    create_docker_compose
    create_systemd_service
    
    # Start monitoring services
    log_info "Starting monitoring services..."
    cd $MONITORING_DIR && docker-compose up -d
    
    # Wait a bit for services to start
    sleep 10
    
    # Configure Nginx and SSL after monitoring stack is running
    configure_nginx
    setup_ssl_certificate
    
    log_info "Monitoring stack with Nginx and SSL deployed successfully!"
    log_info "Access Grafana at: https://${monitoring_domain}"
    log_info "Default credentials - Username: admin, Password: app-monitoring-${ENVIRONMENT}"
    log_info "Installation completed at: $(date)"
}

main "$@"