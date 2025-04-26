# Understanding Packer in AWS AMI Creation

This document explains how HashiCorp Packer works to create custom Amazon Machine Images (AMIs). It focuses on the basic implementation with Amazon Linux 2023 including Nginx and Docker.

## What is Packer?

Packer is an open-source tool developed by HashiCorp that automates the creation of machine images, including AWS AMIs. It creates identical images for multiple platforms from a single configuration.

## Key Components of Our Packer Setup

### 1. Packer Template (`aws-al2023.pkr.hcl`)

The HCL (HashiCorp Configuration Language) template is the core file that defines:
- What plugins Packer needs
- What source image to start with
- How to customize that image
- What to output

```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
```

### 2. Variables Section

Variables make the template reusable across different environments:

```hcl
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
```

### 3. Source Block

The source block defines the starting point:

```hcl
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
}
```

### 4. Build Block

The build block defines what customizations to apply:

```hcl
build {
  name = "build-al2023-nginx-docker"
  sources = [
    "source.amazon-ebs.al2023"
  ]
  
  # Upload the provisioning script
  provisioner "file" {
    source      = "${path.root}/scripts/setup.sh"
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
```

### 5. Provisioning Script (`setup.sh`)

This script performs the actual customization:

```bash
#!/bin/bash
set -e

# Update the system
sudo dnf update -y

# Install Nginx
sudo dnf install -y nginx

# Configure Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Docker
sudo dnf install -y docker

# Configure Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker ec2-user
```

## How Packer Works Step-by-Step

1. **Initialization**: `packer init` downloads required plugins
   ```
   packer init aws-al2023.pkr.hcl
   ```

2. **Validation**: `packer validate` checks the template for errors
   ```
   packer validate -var-file="variables/dev.pkrvars.hcl" aws-al2023.pkr.hcl
   ```

3. **Build Process**: `packer build` executes the build
   ```
   packer build -var-file="variables/dev.pkrvars.hcl" aws-al2023.pkr.hcl
   ```

4. **During Build**:
   - Packer launches a temporary EC2 instance using the source AMI
   - Connects to it via SSH
   - Uploads and runs provisioning scripts
   - Verifies installations
   - Creates an AMI from the instance
   - Terminates the instance
   - Returns the AMI ID

## Key Packer Features Used

### 1. Source AMI Filtering

Instead of using a hardcoded AMI ID, we use filters to find the latest appropriate AMI:

```hcl
source_ami_filter {
  filters = {
    name                = "al2023-ami-*-kernel-6.1-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["137112412989"] # Amazon's owner ID
}
```

This ensures we always start with the latest base image with security updates.

### 2. Variable Files

Using separate variable files (`dev.pkrvars.hcl` and `prod.pkrvars.hcl`) allows environment-specific configurations:

```hcl
# dev.pkrvars.hcl
region         = "us-east-1"
instance_type  = "t2.micro"
ami_name_prefix = "al2023-nginx-docker-dev"
```

```hcl
# prod.pkrvars.hcl
region         = "us-east-1"
instance_type  = "t2.medium"
ami_name_prefix = "al2023-nginx-docker-prod"
```

### 3. Provisioners

Packer uses provisioners to customize the instance:

- **File provisioner**: Uploads the setup script
  ```hcl
  provisioner "file" {
    source      = "${path.root}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
  }
  ```

- **Shell provisioner**: Executes commands or scripts
  ```hcl
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }
  ```

### 4. AMI Naming and Tagging

Dynamic naming with timestamps ensures unique AMI names:

```hcl
ami_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
```

Tags help with organization and filtering:

```hcl
tags = {
  Name        = "${var.ami_name_prefix}"
  Environment = "training"
  Builder     = "Packer"
  BuildDate   = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
}
```

## Common Challenges and Solutions

### 1. Finding the Right Source AMI

**Issue**: Identifying the correct Amazon Linux 2023 AMI pattern.

**Solution**: Adjust the filter pattern (`al2023-ami-*-kernel-6.1-x86_64`), or use the AWS CLI to discover current naming patterns:

```bash
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*" --query 'Images[*].[ImageId,Name,CreationDate]' --output table
```

### 2. File Path Issues

**Issue**: Packer can't find the script files.

**Solution**: Use the `${path.root}` variable to reference paths relative to the template:

```hcl
source = "${path.root}/scripts/setup.sh"
```

### 3. SSH Connection Issues

**Issue**: Packer can't connect to the instance.

**Solution**: Check:
- The correct SSH username (`ec2-user` for Amazon Linux)
- Security group rules allow SSH access
- Increase the SSH timeout if needed

## Best Practices Implemented

1. **Immutable Infrastructure**: Create new AMIs instead of modifying existing servers
2. **Versioning**: Use timestamps in AMI names for versioning
3. **Parameterization**: Use variables for configuration
4. **Verification**: Include validation steps to ensure software is installed correctly
5. **Documentation**: Tag AMIs with build information
6. **Base Image Updates**: Use filters to get the latest security-patched base image



##  Points Covered

- **Infrastructure as Code**: How Packer templates define infrastructure in code
- **AMI Automation**: How to automate the AMI creation process
- **Reusability**: How variables and parameters make templates reusable
- **Verification**: How to validate that provisioning was successful
- **AWS Integration**: How Packer integrates with AWS services
- **CI/CD Integration**: How Packer fits into CI/CD pipelines with GitHub Actions

This basic Packer implementation provides a solid foundation for creating consistent, automated AMIs for your infrastructure, ensuring that all instances start from an identical, well-configured base.