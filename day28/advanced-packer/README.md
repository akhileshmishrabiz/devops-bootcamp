# Advanced AWS AMI Builder with Packer

This project demonstrates advanced techniques for building custom Amazon Machine Images (AMIs) using HashiCorp Packer. It includes:

1. **KMS Encryption** - AMIs are encrypted using AWS KMS keys
2. **AMI Sharing** - AMIs are automatically shared with specified AWS accounts
3. **Ansible Integration** - Uses Ansible for advanced configuration management
4. **Local Shell Scripts** - Custom provisioning via shell scripts
5. **GitHub Actions Workflow** - Automated CI/CD pipeline for AMI building

## Project Structure

```
advanced-packer/
├── README.md
├── packer/
│   ├── advanced-al2023.pkr.hcl    # Main Packer template
│   └── scripts/
│       └── local_config.sh        # Local shell provisioning script
├── ansible/
│   ├── playbook.yml               # Main Ansible playbook
│   ├── ansible.cfg                # Ansible configuration
│   └── roles/
│       └── common/                # Common role for SSH and system configuration
│           ├── tasks/
│           │   └── main.yml       # Task definitions
│           ├── handlers/
│           │   └── main.yml       # Handlers for services
│           ├── templates/
│           │   └── sshd_config.j2 # SSH configuration template
│           └── defaults/
│               └── main.yml       # Default variables
├── variables/
│   ├── dev.pkrvars.hcl            # Development environment variables
│   └── prod.pkrvars.hcl           # Production environment variables
└── .github/
    └── workflows/
        └── build-ami.yml          # GitHub Actions workflow
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Packer installed (v1.8.0+)
- Ansible installed (v2.9+)
- GitHub account (for GitHub Actions)

## Key Features

### 1. KMS Encryption

AMIs are encrypted using AWS KMS keys for enhanced security. The workflow can automatically create KMS keys if they don't exist.

```hcl
# Packer template excerpt
encrypt_boot    = true
kms_key_id      = var.kms_key_id
```

### 2. AMI Sharing

AMIs are automatically shared with specified AWS accounts:

```hcl
# Packer template excerpt
ami_users       = var.target_account_ids
```

### 3. Ansible Integration

Complex configuration is managed through Ansible:

```hcl
# Packer template excerpt
provisioner "ansible" {
  playbook_file = "${path.root}/../ansible/playbook.yml"
  extra_arguments = [
    "--extra-vars", "ansible_ssh_user=${var.ssh_username}",
    "-v"
  ]
}
```

### 4. Custom SSH Configuration

Ansible creates a hardened SSH configuration:

```yaml
# Ansible task excerpt
- name: Update SSH configuration
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    validate: '/usr/sbin/sshd -t -f %s'
  notify: restart sshd
```

## Local Usage

### Setup

1. Clone the repository and navigate to the project directory:
   ```bash
   cd day28/advanced-packer
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Initialize Packer plugins:
   ```bash
   cd packer
   packer init advanced-al2023.pkr.hcl
   ```

### Building AMIs

1. Validate the Packer template:
   ```bash
   packer validate -var-file="../variables/dev.pkrvars.hcl" advanced-al2023.pkr.hcl
   ```

2. Build the AMI:
   ```bash
   packer build -var-file="../variables/dev.pkrvars.hcl" advanced-al2023.pkr.hcl
   ```

## Using GitHub Actions

The included GitHub Actions workflow automatically builds an AMI when:
- Code is pushed to the main branch
- A pull request is created against the main branch
- Manually triggered via workflow_dispatch

### Setting Up GitHub Actions

1. Add the following secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: Your preferred AWS region (e.g., us-east-1)

2. Push the code to your GitHub repository:
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

3. To manually trigger a build:
   - Go to the "Actions" tab in your GitHub repository
   - Select the "Build Advanced AMI with Packer" workflow
   - Click "Run workflow"
   - Select the environment (dev or prod)
   - Click "Run workflow"

## Creating a KMS Key Manually

If you prefer to create the KMS key manually instead of letting the workflow handle it:

```bash
# Create KMS key
aws kms create-key --description "AMI encryption key" --output json

# Create alias for the key
aws kms create-alias --alias-name alias/dev-ami-encryption-key --target-key-id <key-id>
```



# Explain the advanced concepts:

   - AMI encryption for security
   - Cross-account AMI sharing
   - Ansible vs. shell scripts for provisioning
   - Infrastructure as Code principles
   - KMS encryption setup
   - Sharing mechanisms
   - Ansible role structure
   - GitHub Actions workflow

3. Hands-on Exercises:
   - Modify the SSH configuration template
   - Add additional Ansible roles
   - Create new environment-specific variable files
   - Test AMI sharing between accounts

4. Advanced Topics:
   - AMI lifecycle management
   - Integrating with other AWS services
   - Testing AMIs with Test Kitchen
   - Implementing AMI promotion workflows

## Troubleshooting

### Common Issues:

1. **KMS Key Permissions**:
   If you encounter KMS permission errors, ensure your IAM user/role has permissions to use the specified KMS key.

2. **SSH Connection Issues**:
   If Packer fails to connect to the instance, check:
   - Security group rules allow SSH from your IP
   - The specified SSH username is correct
   - SSH key pair is properly configured

3. **AMI Sharing Failures**:
   If AMI sharing fails:
   - Verify target account IDs are correct
   - Ensure your account has permissions to share AMIs
   - Check for encryption permission issues between accounts
