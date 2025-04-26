#!/bin/bash
set -e

# Print commands and their arguments as they are executed
set -x

echo "Starting local configuration script - $(date)"

# Update the system
echo "Updating system packages"
sudo dnf update -y

# Install basic tools
echo "Installing basic tools"
sudo dnf install -y \
    wget \
    curl \
    vim \
    htop \
    git \
    unzip \
    jq \
    tar \
    telnet \
    net-tools \
    nmap \
    lsof

# Install Docker
echo "Installing Docker"
sudo dnf install -y docker

# Configure Docker
echo "Configuring Docker service"
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
echo "Adding ${USER} to docker group"
sudo usermod -aG docker ${USER}

# Install AWS CLI
echo "Installing AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure system settings
echo "Configuring system settings"

# Increase file descriptor limits
cat <<EOF | sudo tee /etc/security/limits.d/99-custom.conf
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Optimize network settings
cat <<EOF | sudo tee /etc/sysctl.d/99-network-tuning.conf
# Increase system IP port limits
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 1440000
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 4096
EOF

# Apply sysctl changes
sudo sysctl -p /etc/sysctl.d/99-network-tuning.conf

# Create a welcome message
cat <<EOF | sudo tee /etc/motd
*******************************************************************************
*                                                                             *
*                       Advanced AMI Built with Packer                        *
*                                                                             *
* This AMI includes:                                                          *
* - Custom SSH configuration                                                  *
* - Optimized system settings                                                 *
* - Docker pre-installed                                                      *
* - AWS CLI                                                                   *
*                                                                             *
* Build Date: $(date)                                             *
*                                                                             *
*******************************************************************************
EOF

# Create custom directories
sudo mkdir -p /opt/scripts
sudo mkdir -p /opt/logs
sudo mkdir -p /opt/data

# Set ownership
sudo chown -R ${USER}:${USER} /opt/scripts /opt/logs /opt/data

# Verify configurations
echo "Verifying Docker installation"
docker --version

echo "Verifying AWS CLI installation"
aws --version

echo "Local configuration completed successfully - $(date)"