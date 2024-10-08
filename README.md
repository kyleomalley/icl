# ICL (Instant Container Lab)

This project automates the provisioning and configuration of an AWS environment using Terraform and Ansible.

## Primary Goals:
Running `./icl.sh start` will produce the following:

- Automates creating three ec2 nodes, `pce`, `kubernetes-controller`, `kubernetes-worker`
- Uses Route53 to assign DNS entries (Completed)
- Configures and stores publicly trusted TLS certificates on each node. (Completed)
- Configures an outbound HTTP Proxy (Tinyproxy) on `pce` for use by the Kubernetes cluster nodes. (Completed)
- Configures Kubernetes and configures outbound proxy. (Completed)
- Launches a simple "Hello World" container app. (Completed)
- Ansible playbook to launch a single node PCE Cluster (Completed)
- Automate creating AWS IAM Policy and Attaching roles to EC2 instances (or distribute aws configuration). 

Cavaets:
 - Requires a significant configuration on AWS for network security rules, ec2 roles (for S3 and Route53 changes).
 - Configuration (secrets) file is a WIP and should be moved to something more reasonable, probably Amazon Vault or a local vault store.
 - Most of the opinionated (non-default / non-best practice) decisions were made to maximize compatibility with specific software (e.g using RSA certificates). 


Additionally,`icl.sh` should be able to `destroy`, `suspend` and `unsuspend` all created nodes. (Completed)

## Architecture Overview
```mermaid 
graph TB;
    AC{{Linux Workstation}} -. "AWS API (Terraform)" .-> AWS((AWS));
    AC -- "SSH (Ansible) & HTTPS" --> SG{{"*AWS Security Group*"}};
    AC --> LetsEncrypt[LetsEncrypt];

    S3[S3] <--> AWS;
    Route53[Route53] <--> AWS;

    AWS --> AWS_Instances(AWS Subgraph);

    subgraph AWS_Instances[AWS EC2];
        EC2_1[pce];
        EC2_2[K8s_controller];
        EC2_3[K8s_worker];
    end;
    
    SG --> EC2_1;
    SG --> EC2_2;
    SG --> EC2_3;
```
## Secondary Goals:
 - Include Ansible Playbooks to install various container-based services.
    - Illumio PCE. (Working, minus initial user account creation)

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
    - See `aws-iam-policy-simple.json` example Access Management Policy. This is unlikely to be up-to-date.
    - Configure with: `aws configure`
## Setup Instructions

### Clone the Repository

```bash
git clone https://github.com/kyleomalley/icl.git
cd icl
chmod +x icl.sh
```

### Create secrets.tfvars (`touch secrets.tfvars`)

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
    - `ansible all -m ping`
- AWS Permissions: Ensure that your AWS credentials have sufficient permissions to create and manage EC2 instances, security groups, and other resources.
- Python Interpreter: If Ansible fails due to a Python version issue, verify that the correct interpreter path is specified in the PYTHON_INTERPRETER variable.
