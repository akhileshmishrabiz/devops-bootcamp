# AWS AMI Builder with Packer

This project demonstrates how to build custom Amazon Machine Images (AMIs) using HashiCorp Packer with Amazon Linux 2023 as the base image. The resulting AMI comes pre-installed with Nginx and Docker.

## Project Structure

```
packer-aws-ami-project/
├── README.md
├── packer/
│   ├── aws-al2023.pkr.hcl  # Main Packer template
│   └── scripts/
│       └── setup.sh        # Provisioning script
├── variables/
│   ├── dev.pkrvars.hcl     # Development environment variables
│   └── prod.pkrvars.hcl    # Production environment variables
└── .github/
    └── workflows/
        └── build-ami.yml   # GitHub Actions workflow
```

## Prerequisites

- AWS Account
- AWS CLI installed and configured
- Packer installed (v1.8.0+)
- GitHub account (for GitHub Actions)

## Local Usage

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/akhileshmishrabiz/devops-bootcamp.git
   cd day28/packer-aws-ami-project
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Install with download and Initialize Packer plugins:
 
 https://developer.hashicorp.com/packer/tutorials/aws-get-started/get-started-install-cli

   ```bash
   # Mac
   brew tap hashicorp/tap
   brew install hashicorp/tap/packer
   packer --version
   cd packer
   packer init ./aws-al2023.pkr.hcl
   ```

### Building AMIs

1. Validate the Packer template:
   ```bash
   packer validate -var-file="../variables/dev.pkrvars.hcl" aws-al2023.pkr.hcl
   ```

2. Build the AMI:
   ```bash
   packer build -var-file="../variables/dev.pkrvars.hcl" aws-al2023.pkr.hcl
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
   - Select the "Build AMI with Packer" workflow
   - Click "Run workflow"
   - Select the environment (dev or prod)
   - Click "Run workflow"

## Using the AMI

After building the AMI, you can launch an EC2 instance using it:

1. Go to the AWS EC2 Console
2. Click "Launch Instance"
3. Click "My AMIs" and select your newly created AMI
4. Complete the instance launch wizard
5. Once the instance is running, access the Nginx welcome page at http://[EC2-PUBLIC-IP]

## Customization

- Modify `scripts/setup.sh` to install additional packages or configure the system
- Add more environment-specific variable files in the `variables/` directory
- Update the Packer template to add more provisioners or customize the build process

## Teaching Tips

When using this project for teaching:

1. Start by explaining the basic concepts:
   - What is an AMI and why use custom AMIs
   - How Packer works with AWS
   - The role of provisioners in Packer

2. Walk through each file:
   - `aws-al2023.pkr.hcl`: The main template file
   - `setup.sh`: The provisioning script
   - Variable files: How to parameterize builds
   - GitHub Actions workflow: How to automate builds

3. Demonstrate the build process:
   - Show validation and build commands
   - Explain the output and AMI creation process
   - Launch an EC2 instance with the AMI

4. Assignment ideas:
   - Modify the setup script to install additional software
   - Add more variables to make the template more flexible
   - Create a multi-region build configuration
   - Set up an automated testing workflow for the AMI

## License

This project is licensed under the MIT License.