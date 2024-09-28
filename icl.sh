#!/bin/bash

# Ensure we exit on error
set -e

# Path to the secrets file
SECRETS_FILE="secrets.tfvars"

# Check if the secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo "Error: The secrets file $SECRETS_FILE does not exist."
  exit 1
fi

# Export necessary variables from secrets.tfvars
export AWS_ACCESS_KEY=$(grep 'aws_access_key' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export AWS_SECRET_KEY=$(grep 'aws_secret_key' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export DOMAIN_NAME=$(grep 'domain_name' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export HOSTED_ZONE_ID=$(grep 'hosted_zone_id' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export KEY_NAME=$(grep 'key_name' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export KEY_PATH=$(grep 'key_path' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')
export PROJECT_NAME=$(grep 'project_name' $SECRETS_FILE | awk -F ' = ' '{print $2}' | tr -d '"')


# Configure AWS CLI with the extracted credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY
aws configure set aws_secret_access_key $AWS_SECRET_KEY


# Function to start the infrastructure
start_infrastructure() {
  echo "Checking existing EC2 instances for project '$PROJECT_NAME'..."
  existing_instances=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=${PROJECT_NAME}" "Name=instance-state-name,Values=pending,running" --query "Reservations[*].Instances[*].[InstanceId]" --output text)

  instance_count=$(echo "$existing_instances" | wc -w | tr -d ' ')

  if [ "$instance_count" -ge 3 ]; then
    echo "Error: There are already $instance_count instances running for project '$PROJECT_NAME'. No more instances will be created."
    exit 1
  fi

  echo "Initializing Terraform..."
  cd terraform/
  terraform init

  echo "Applying Terraform configuration..."
  terraform apply -var-file="../$SECRETS_FILE" -auto-approve

  echo "Retrieving instance IPs..."
  PCE_IP=$(terraform output -raw pce_ip)
  CONTROLLER_IP=$(terraform output -raw kubernetes_controller_ip)
  NODE_IP=$(terraform output -raw kubernetes_node_ip)

  cd ..

  echo "Generating Ansible inventory..."
  cat <<EOL > ansible/inventory/hosts
[pce_group]
pce ansible_host=${PCE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH} ansible_python_interpreter=${PYTHON_INTERPRETER}

[kubernetes_controller_group]
controller ansible_host=${CONTROLLER_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH} ansible_python_interpreter=${PYTHON_INTERPRETER}

[kubernetes_node_group]
node ansible_host=${NODE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH} ansible_python_interpreter=${PYTHON_INTERPRETER}
EOL

  echo "Waiting for instances to finish ssh setup..."
  sleep 15

  echo "Running Ansible playbooks..."
  ansible-playbook -i ansible/inventory/hosts ansible/playbooks/pce.yml
  ansible-playbook -i ansible/inventory/hosts ansible/playbooks/kubernetes.yml

  echo "Infrastructure setup complete."
}

# Function to suspend the infrastructure (stop EC2 instances)
suspend_infrastructure() {
  echo "Suspending all EC2 instances..."
  cd terraform/
  terraform apply -var-file="../$SECRETS_FILE" -var 'instance_state=stopped' -auto-approve
  cd ..
  echo "Infrastructure suspended."
}

# Function to unsuspend the infrastructure (restart EC2 instances)
unsuspend_infrastructure() {
  echo "Unsuspending all EC2 instances..."
  cd terraform/
  terraform apply -var-file="../$SECRETS_FILE" -var 'instance_state=running' -auto-approve
  cd ..
  
  echo "Waiting for instances to finish ssh setup..."
  sleep 15

  # Run the Ansible playbooks to ensure services are running after unsuspend
  echo "Running Ansible playbooks to ensure services are running..."
  ansible-playbook -i ansible/inventory/hosts ansible/playbooks/pce.yml
  ansible-playbook -i ansible/inventory/hosts ansible/playbooks/kubernetes.yml
}

# Function to destroy the infrastructure
destroy_infrastructure() {
  echo "Destroying Terraform-managed infrastructure..."
  cd terraform/
  terraform destroy -var-file="../$SECRETS_FILE" -auto-approve
  cd ..
  echo "Infrastructure destroyed."
}

# Function to list available RHEL 9 AMIs
list_amis() {
  echo "Listing available RHEL 9 AMIs..."
  aws ec2 describe-images \
    --filters "Name=name,Values=RHEL-9*-x86_64-*" "Name=architecture,Values=x86_64" "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" \
    --query "Images[*].[ImageId,OwnerId,Name,CreationDate]" \
    --output table
}

# Function to list existing EC2 instances for the project
list_instances() {
  echo "Listing existing EC2 instances for project '$PROJECT_NAME'..."
  echo "------------------------------------------------------------------------------------------------------------------------------------------------"
  echo "| Instance ID        | Instance Type | Public IP       | SSH Key      | Security Group    | Launch Time                | State    | Name              |"
  echo "------------------------------------------------------------------------------------------------------------------------------------------------"
  aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=${PROJECT_NAME}" "Name=instance-state-name,Values=pending,running" \
    --query "Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,KeyName,SecurityGroups[0].GroupName,LaunchTime,State.Name,Tags[?Key=='Name'].Value|[0]]" \
    --output table
}

# Main script logic based on argument
case "$1" in
  start)
    start_infrastructure
    ;;
  suspend)
    suspend_infrastructure
    ;;
  unsuspend)
    unsuspend_infrastructure
    ;;
  destroy)
    destroy_infrastructure
    ;;
  list_amis)
    list_amis
    ;;
  list)
    list_instances
    ;;
  *)
    echo "Usage: $0 {start|suspend|unsuspend|destroy|list_amis|list}"
    exit 1
esac