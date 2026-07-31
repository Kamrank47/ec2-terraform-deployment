# deploy.sh
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <environment> <command>"
    echo "Example: ./deploy.sh dev plan"
    exit 1
fi

ENV=$1
COMMAND=$2
ARGUMENTS="${@:3}"

# Validate environment
if [[ ! "$ENV" =~ ^(dev|test|stage|prod)$ ]]; then
    echo "Invalid environment. Use dev, stage, or prod"
    exit 1
fi

# Initialize with correct backend
echo "Initializing Terraform for $ENV environment..."
terraform init -reconfigure -backend-config=backend-$ENV.hcl

# Validate Terraform code
echo "Validating Terraform code..."
terraform validate

if [ $? -ne 0 ]; then
    echo "Terraform validation failed. Exiting..."
    exit 1
fi


# Run terraform command with correct var file
case $COMMAND in
    "plan")
        terraform plan -var-file=$ENV.tfvars $ARGUMENTS
        ;;
    "apply")
        terraform apply -var-file=$ENV.tfvars $ARGUMENTS
        ;;
    "destroy")
        terraform destroy -var-file=$ENV.tfvars $ARGUMENTS
        ;;
    *)
        echo "Invalid command. Use plan, apply, or destroy"
        exit 1
        ;;
esac

# Make script executable
# chmod +x deploy.sh

# For development environment
# ./deploy.sh dev plan
# ./deploy.sh dev apply