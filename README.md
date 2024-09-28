# ICL

This project automates the provisioning and configuration of an AWS environment using Terraform and Ansible. The setup includes a simple HTTP serving node and a Kubernetes cluster.

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

### Update Configuration Variables
Open icl.sh and update the following variables if necessary:

	•	PROJECT_NAME: The name of your project (default is "icl-dev").
	•	KEY_NAME: The name of your existing AWS SSH key pair (default is "ssh-dev").
	•	KEY_PATH: The path to your SSH private key file (default is "~/.ssh/ssh-dev.pem").
	•	SECURITY_GROUP_NAME: The name of the security group (default is "icl-dev").
	•	PYTHON_INTERPRETER: The path to the Python interpreter on your EC2 instances (default is "/usr/bin/python3.9").


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

## HTTP Service on PCE Node

A simple HTTP server is automatically started on the PCE node on port 8080. You can access this service by navigating to `http://<PCE_IP>:8080` after the infrastructure is up and running.


## Generated Files

Some files, such as the Ansible inventory, are generated automatically by the icl.sh script. These files are ignored by Git and should not be manually edited.

## Troubleshooting

- SSH Connection Issues: Ensure that your SSH key is correctly configured and that the security group allows inbound SSH traffic on port 22.
    - `ansible pce -i ansible/inventory/hosts -m ping -u ec2-user --private-key ~/.ssh/ssh-dev.pem`
- AWS Permissions: Ensure that your AWS credentials have sufficient permissions to create and manage EC2 instances, security groups, and other resources.
- Python Interpreter: If Ansible fails due to a Python version issue, verify that the correct interpreter path is specified in the PYTHON_INTERPRETER variable.
