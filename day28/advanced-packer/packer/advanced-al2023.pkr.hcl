packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# Variables for customization
variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "al2023-advanced"
}

variable "kms_key_id" {
  type    = string
  description = "KMS key ID for encrypting the AMI"
}

variable "target_account_ids" {
  type    = list(string)
  description = "List of AWS account IDs to share the AMI with"
  default = []
}

variable "vpc_id" {
  type    = string
  description = "VPC ID for the temporary instance"
  default = ""
}

variable "subnet_id" {
  type    = string
  description = "Subnet ID for the temporary instance"
  default = ""
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

# Local variables for reuse
locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name  = "${var.ami_name_prefix}-${local.timestamp}"
}

# The source block defines where to start
source "amazon-ebs" "al2023" {
  ami_name        = local.ami_name
  ami_description = "Amazon Linux 2023 with advanced configurations"
  instance_type   = var.instance_type
  region          = var.region
  
  # Network configuration
  vpc_id    = var.vpc_id != "" ? var.vpc_id : null
  subnet_id = var.subnet_id != "" ? var.subnet_id : null
  
  # AMI encryption with KMS
  encrypt_boot    = true
  kms_key_id      = var.kms_key_id
  
  # Share AMI with other accounts
  ami_users       = var.target_account_ids
  
  # Find the latest Amazon Linux 2023 AMI
  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-kernel-6.1-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"] # Amazon's owner ID
  }
  
  ssh_username = var.ssh_username
  
  # Configure SSH connection timeout
  ssh_timeout = "10m"
  
  # Add tags to the resulting AMI
  tags = {
    Name        = local.ami_name
    Environment = "{{user `environment`}}"
    Builder     = "Packer"
    BuildDate   = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    Encrypted   = "true"
    KmsKeyId    = var.kms_key_id
  }
  
  # Add tags to the snapshot that's created
  snapshot_tags = {
    Name = "${local.ami_name}-snapshot"
  }
}

# The build block defines what we're going to do with the source
build {
  name = "build-advanced-al2023"
  sources = [
    "source.amazon-ebs.al2023"
  ]
  
  # Upload and execute local provisioning script
  provisioner "shell" {
    script = "${path.root}/scripts/local_config.sh"
  }
  
  # Run Ansible playbook for more complex configurations
  provisioner "ansible" {
    playbook_file = "${path.root}/../ansible/playbook.yml"
    extra_arguments = [
      "--extra-vars", "ansible_ssh_user=${var.ssh_username}",
      "-v"
    ]
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.root}/../ansible/ansible.cfg",
      "ANSIBLE_FORCE_COLOR=1"
    ]
  }
  
  # Add final configuration and verification
  provisioner "shell" {
    inline = [
      "echo 'Verifying installations and configurations...'",
      "sudo systemctl status sshd",
      "ls -la /etc/ssh/",
      "cat /etc/os-release",
      "echo 'AMI build completed successfully!'"
    ]
  }
  
  # Post-processor to output manifest
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      ami_name = local.ami_name
      region   = var.region
    }
  }
}