#!/bin/bash

# TravelMemory Frontend Deployment Script
# Standalone script for deploying only the frontend
# Usage: bash deploy-frontend.sh

set -e

# Configuration
FRONTEND_DIR="$HOME/TravelMemory/frontend"
FRONTEND_PORT=8080
NODE_ENV="production"

echo "=========================================="
echo "TravelMemory Frontend Deployment"
echo "=========================================="

# Install Node.js if needed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Install Nginx if needed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

# Create frontend directory if it doesn't exist
mkdir -p "$FRONTEND_DIR"
cd "$FRONTEND_DIR"

# If no package.json, assume we need to clone
if [ ! -f "package.json" ]; then
    echo "Repository not found. Please clone first:"
    echo "git clone https://github.com/UnpredictablePrashant/TravelMemory.git ~/TravelMemory"
    exit 1
fi

echo "Installing dependencies..."
npm install --production

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << 'EOF'
REACT_APP_BACKEND_URL=https://api.yourdomain.com
REACT_APP_ENV=production
EOF
    echo ".env file created - PLEASE UPDATE WITH YOUR BACKEND URL"
fi

echo "Building React application..."
npm run build

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/travelmemory-frontend > /dev/null << 'NGINX_EOF'
server {
    listen 8080;
    server_name _;
    
    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/json;
    gzip_min_length 1024;
    
    # Cache policy for static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Main app location - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_EOF

# Enable site if not already enabled
if [ ! -L /etc/nginx/sites-enabled/travelmemory-frontend ]; then
    sudo ln -s /etc/nginx/sites-available/travelmemory-frontend /etc/nginx/sites-enabled/
fi

# Remove default site if enabled
if [ -L /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "=========================================="
echo "✓ Frontend Deployment Complete"
echo "=========================================="
echo "Port: $FRONTEND_PORT"
echo "Build Location: $FRONTEND_DIR/build"
echo ""
echo "Check Nginx status:"
sudo systemctl status nginx --no-pager | head -3
echo ""
echo "View Nginx error logs:"
echo "sudo tail -f /var/log/nginx/error.log"
