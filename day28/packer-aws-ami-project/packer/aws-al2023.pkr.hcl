packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables for customization
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "al2023-nginx-docker"
}

# The source block defines where to start
source "amazon-ebs" "al2023" {
  ami_name        = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  ami_description = "Amazon Linux 2023 with Nginx and Docker pre-installed"
  instance_type   = var.instance_type
  region          = var.region
  
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
  
  ssh_username = "ec2-user"
  
  # Add tags to the resulting AMI
  tags = {
    Name        = "${var.ami_name_prefix}"
    Environment = "training"
    Builder     = "Packer"
    BuildDate   = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  }
  
  # Add tags to the snapshot that's created
  snapshot_tags = {
    Name = "${var.ami_name_prefix}-snapshot"
  }
}

# The build block defines what we're going to do with the source
build {
  name = "build-al2023-nginx-docker"
  sources = [
    "source.amazon-ebs.al2023"
  ]
  
  # Upload the provisioning script
  provisioner "file" {
    source      = "scripts/setup.sh"
    destination = "/tmp/setup.sh"
  }
  
  # Execute the provisioning script
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }
  
  # Verify installations
  provisioner "shell" {
    inline = [
      "nginx -v",
      "docker --version",
      "sudo systemctl status nginx",
      "sudo systemctl status docker"
    ]
  }
}