#!/bin/bash

# TravelMemory Backend Deployment Script
# Standalone script for deploying only the backend
# Usage: bash deploy-backend.sh

set -e

# Configuration
BACKEND_DIR="$HOME/TravelMemory/backend"
PM2_APP_NAME="travelmemory-backend"
BACKEND_PORT=3000
NODE_ENV="production"

echo "=========================================="
echo "TravelMemory Backend Deployment"
echo "=========================================="

# Install Node.js if needed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Install PM2 globally if needed
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
    pm2 startup
fi

# Create backend directory if it doesn't exist
mkdir -p "$BACKEND_DIR"
cd "$BACKEND_DIR"

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
PORT=3000
NODE_ENV=production
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/travel_memory
FRONTEND_URL=https://yourdomain.com
JWT_SECRET=change_this_to_strong_secret
LOG_LEVEL=info
EOF
    echo ".env file created - PLEASE UPDATE WITH YOUR VALUES"
fi

# Stop existing process
echo "Stopping existing process..."
pm2 stop "$PM2_APP_NAME" 2>/dev/null || true
pm2 delete "$PM2_APP_NAME" 2>/dev/null || true

# Start with PM2
echo "Starting backend with PM2..."
pm2 start index.js --name "$PM2_APP_NAME" --env production --max-memory-restart 500M

# Configure PM2 to start on reboot
pm2 startup systemd -u ubuntu --hp ~/TravelMemory
pm2 save

echo ""
echo "=========================================="
echo "✓ Backend Deployment Complete"
echo "=========================================="
echo "Port: $BACKEND_PORT"
echo "PM2 App: $PM2_APP_NAME"
echo "Status:"
pm2 status
echo ""
echo "View logs: pm2 logs $PM2_APP_NAME"
echo "Restart: pm2 restart $PM2_APP_NAME"
