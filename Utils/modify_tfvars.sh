#!/bin/bash

# Check if environment parameter is provided
if [ -z "$1" ]; then
    echo "Environment parameter is required"
    exit 1
fi

ENVIRONMENT=$1
TFVARS_FILE="${ENVIRONMENT}.tfvars"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    echo "TFVars file ${TFVARS_FILE} not found!"
    exit 1
fi

# Define the new profile value
new_profile=""

# Use sed to update the AWS_PROFILE value in the tfvars file
sed -i -E "s/^AWS_PROFILE[[:space:]]*=[[:space:]]*\".*\"/AWS_PROFILE = \"$new_profile\"/" "$TFVARS_FILE"

echo "Successfully modified ${TFVARS_FILE}"

# Use sed to update the profile value in backend-dev.hcl
sed -i -E "s/^profile[[:space:]]*=[[:space:]]*\".*\"/profile = \"$new_profile\"/" "backend-${ENVIRONMENT}.hcl"



