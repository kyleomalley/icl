provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

variable "project_name" {
  description = "The name of the project, used for tagging resources"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the EC2 instances"
  type        = string
}

variable "security_group_name" {
  description = "The name of the security group to use for the EC2 instances"
  type        = string
}

variable "pce_iam_instance_profile" {
  description = "The IAM instance profile ARN"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for DNS records"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route 53 hosted zone ID"
  type        = string
}

data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-9*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "pce" {
  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  security_groups = [var.security_group_name]
  iam_instance_profile = var.pce_iam_instance_profile

  tags = {
    Name    = "pce"
    Project = var.project_name
  }

  associate_public_ip_address = true
}

resource "aws_instance" "kubernetes_controller" {
  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  security_groups = [var.security_group_name]

  tags = {
    Name    = "kubernetes-controller"
    Project = var.project_name
  }

  associate_public_ip_address = true
}

resource "aws_instance" "kubernetes_node" {
  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  security_groups = [var.security_group_name]

  tags = {
    Name    = "kubernetes-node"
    Project = var.project_name
  }

  associate_public_ip_address = true
}

output "pce_ip" {
  value = aws_instance.pce.public_ip
}

output "kubernetes_controller_ip" {
  value = aws_instance.kubernetes_controller.public_ip
}

output "kubernetes_node_ip" {
  value = aws_instance.kubernetes_node.public_ip
}

# Route 53 DNS Records
resource "aws_route53_record" "pce" {
  zone_id = var.hosted_zone_id
  name    = "pce.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.pce.public_ip]
}

resource "aws_route53_record" "kubernetes_controller" {
  zone_id = var.hosted_zone_id
  name    = "controller.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kubernetes_controller.public_ip]
}

resource "aws_route53_record" "kubernetes_node" {
  zone_id = var.hosted_zone_id
  name    = "node.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kubernetes_node.public_ip]
}
