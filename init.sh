#!/bin/bash

# TravelMemory EC2 Instance Initialization Script
# Run this on a fresh EC2 instance to prepare for deployment
# Usage: bash init.sh

set -e

echo "=========================================="
echo "TravelMemory EC2 Instance Initialization"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install basic tools
echo "Installing basic tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Node.js
echo "Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Nginx installed and started"

# Install PM2
echo "Installing PM2..."
sudo npm install -g pm2
pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save

echo "PM2 installed and configured"

# Create application directory
echo "Creating application directory..."
mkdir -p /home/ubuntu/TravelMemory
cd /home/ubuntu/TravelMemory

# Clone repository
echo "Cloning repository..."
if [ -d "/home/ubuntu/TravelMemory/.git" ]; then
    echo "Repository already exists, pulling latest changes..."
    git pull origin main
else
    git clone https://github.com/UnpredictablePrashant/TravelMemory.git /tmp/travelmemory
    mv /tmp/travelmemory/* /home/ubuntu/TravelMemory/
    mv /tmp/travelmemory/.git /home/ubuntu/TravelMemory/
fi

# Set proper permissions
echo "Setting permissions..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/TravelMemory

# Create deployment scripts
echo "Creating deployment scripts..."
chmod +x /home/ubuntu/TravelMemory/deploy.sh
chmod +x /home/ubuntu/TravelMemory/deploy-backend.sh
chmod +x /home/ubuntu/TravelMemory/deploy-frontend.sh

# Configure UFW Firewall
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw --force enable

echo ""
echo "=========================================="
echo "✓ EC2 Instance Initialization Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. SSH into your EC2 instance:"
echo "   ssh -i your-key.pem ubuntu@your-instance-ip"
echo ""
echo "2. Deploy the application:"
echo "   cd /home/ubuntu/TravelMemory"
echo "   bash deploy.sh both"
echo ""
echo "3. Update configuration:"
echo "   nano backend/.env"
echo "   nano frontend/.env"
echo ""
echo "4. Restart services:"
echo "   pm2 restart travelmemory-backend"
echo "   sudo systemctl reload nginx"
echo ""
echo "5. Configure SSL:"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot certonly --nginx -d yourdomain.com"
echo ""
