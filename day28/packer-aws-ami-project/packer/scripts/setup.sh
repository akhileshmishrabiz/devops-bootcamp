#!/bin/bash
set -e

# Print commands and their arguments as they are executed
set -x

echo "Starting setup script - $(date)"

# Update the system
echo "Updating system packages"
sudo dnf update -y

# Install Nginx
echo "Installing Nginx"
sudo dnf install -y nginx

# Configure Nginx to start on boot and start it now
echo "Configuring Nginx service"
sudo systemctl enable nginx
sudo systemctl start nginx

# Create a custom welcome page
echo "Creating custom welcome page"
cat <<EOF | sudo tee /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Custom AMI Built with Packer</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
        }
        h1 {
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Success! AMI Built with Packer</h1>
        <p>This Amazon Linux 2023 instance has been provisioned with:</p>
        <ul>
            <li>Nginx - Web Server</li>
            <li>Docker - Container Runtime</li>
        </ul>
        <p>Build Date: $(date)</p>
    </div>
</body>
</html>
EOF

# Install Docker
echo "Installing Docker"
sudo dnf install -y docker

# Configure Docker to start on boot and start it now
echo "Configuring Docker service"
sudo systemctl enable docker
sudo systemctl start docker

# Add ec2-user to the docker group so it can run docker commands without sudo
echo "Adding ec2-user to docker group"
sudo usermod -aG docker ec2-user

# Install docker-compose
echo "Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add some useful aliases for Docker
echo "Adding Docker aliases to .bashrc"
cat <<EOF >> /home/ec2-user/.bashrc
# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias di='docker images'
alias dps='docker ps'
alias dpsa='docker ps -a'
EOF

# Verify installations
echo "Verifying installations"
nginx -v
docker --version
docker-compose --version

echo "Setup completed successfully - $(date)"