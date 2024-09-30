# ICL (Instant Container Lab)

This project automates the provisioning and configuration of an AWS environment using Terraform and Ansible.

## Primary Goals:
Running `./icl.sh start` will produce the following:

- Automates creating three ec2 nodes, `pce`, `kubernetes-controller`, `kubernetes-worker`
- Uses Route53 to assign DNS entries (Completed)
- Configures and stores publicaly trusted TLS certificates on each node. (WIP)
- Configures an outbound HTTP Proxy (Tinyproxy) on `pce` for use by the Kubernetes cluster nodes. (WIP)
- Configures Kubernetes and configures outbound proxy. (WIP)
- Launches a simple "Hello World" container app. (Not started)

Additionally,`icl.sh` should be able to `destroy`, `suspend` and `unsuspend` all created nodes. (Completed)

## Secondary Goals:
 - Include Ansible Playbooks to install various container-based services.
    - Illumio PCE. (WIP)

## Prerequisites

- MacOS/Linux (Ubuntu). Tested on Windows via WSL 1.0 only.
- [Terraform](https://www.terraform.io/downloads) (>= v0.12)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (>= v2.9)

- AWS
    - [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials
    - Mac: `brew install awscli`
    - Ubuntu: `sudo apt install awscli`

- An existing SSH key pair in AWS (e.g., `ssh-dev`)
- An existing security group in AWS (e.g. `ilo-dev`)
- An AWS IAM Account with appropriate permissions policy applied.
    - See `aws-iam-policy-simple.json` example Access Management Policy
    - Configure with: `aws configure`
## Setup Instructions

### Clone the Repository

```bash
git clone https://github.com/kyleomalley/icl.git
cd icl
chmod +x icl.sh
```

### Initalize terraform (first run only)
```bash
cd terraform
terraform init
```


### Create secrets.tfvars

```secrets.tfvars
# AWS Credentials
aws_access_key  = "<>"
aws_secret_key  = "<>"

# Domain Information
domain_name     = "<domain.com>"
hosted_zone_id  = "<aws_zone_id>"

# SSH Key Information
key_name        = "ssh-dev"
key_path        = "~/.ssh/ssh-dev.pem"

# Project Information
project_name    = "icl-dev"
security_group_name = "icl-dev"

# Python Version https://docs.ansible.com/ansible-core/2.17/reference_appendices/interpreter_discovery.html
python_interpreter    = "/usr/bin/python3.9"
```

### Usage

Use the `icl.sh` script to manage the infrastructure.

- **Start the Infrastructure**:

    ```bash
    ./icl.sh start
    ```

- **Suspend the Infrastructure**:

    ```bash
    ./icl.sh suspend
    ```

- **Unsuspend the Infrastructure**:

    ```bash
    ./icl.sh unsuspend
    ```

- **Destroy the Infrastructure**:

    ```bash
    ./icl.sh destroy
    ```

- **List Existing Instances**:

    ```bash
    ./icl.sh list
    ```

- **List Available RHEL 9 AMIs**:

    ```bash
    ./icl.sh list_amis
    ```

## Generated Files

Some files, such as the Ansible inventory, are generated automatically by the icl.sh script. These files are ignored by Git and should not be manually edited.

## Troubleshooting

- SSH Connection Issues: Ensure that your SSH key is correctly configured and that the security group allows inbound SSH traffic on port 22.
    - `ansible pce -i ansible/inventory/hosts -m ping -u ec2-user --private-key ~/.ssh/ssh-dev.pem`
- AWS Permissions: Ensure that your AWS credentials have sufficient permissions to create and manage EC2 instances, security groups, and other resources.
- Python Interpreter: If Ansible fails due to a Python version issue, verify that the correct interpreter path is specified in the PYTHON_INTERPRETER variable.
