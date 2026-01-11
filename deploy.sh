#!/bin/bash

# TravelMemory Application - AWS EC2 Deployment Script
# This script automates the deployment of backend and frontend on EC2
# Usage: bash deploy.sh [backend|frontend|both]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/UnpredictablePrashant/TravelMemory.git"
APP_DIR="/home/ubuntu/TravelMemory"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
NODEJS_VERSION="18"
PM2_APP_NAME="travelmemory-backend"
FRONTEND_PORT=8080
BACKEND_PORT=3000

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Update system
update_system() {
    print_header "Step 1: Updating System Packages"
    sudo apt update
    sudo apt upgrade -y
    print_success "System packages updated"
}

# Install Node.js
install_nodejs() {
    print_header "Step 2: Installing Node.js and npm"
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        print_info "Node.js $NODE_VERSION already installed"
        return 0
    fi
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | sudo -E bash -
    sudo apt install -y nodejs
    
    print_success "Node.js $(node -v) and npm $(npm -v) installed"
}

# Install Git
install_git() {
    print_header "Step 3: Installing Git"
    
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version)
        print_info "$GIT_VERSION already installed"
        return 0
    fi
    
    sudo apt install -y git
    print_success "Git installed"
}

# Install Nginx
install_nginx() {
    print_header "Step 4: Installing Nginx"
    
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1)
        print_info "$NGINX_VERSION already installed"
        return 0
    fi
    
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    print_success "Nginx installed and started"
}

# Install PM2
install_pm2() {
    print_header "Step 5: Installing PM2"
    
    if command -v pm2 &> /dev/null; then
        print_info "PM2 already installed"
        return 0
    fi
    
    sudo npm install -g pm2
    pm2 startup
    pm2 save
    print_success "PM2 installed and configured"
}

# Clone repository
clone_repository() {
    print_header "Step 6: Cloning Repository"
    
    if [ -d "$APP_DIR" ]; then
        print_info "Repository already exists at $APP_DIR, updating..."
        cd "$APP_DIR"
        git pull origin main
    else
        print_info "Cloning repository from $REPO_URL"
        git clone "$REPO_URL" "$APP_DIR"
    fi
    
    print_success "Repository cloned/updated"
}

# Deploy Backend
deploy_backend() {
    print_header "Deploying Backend"
    
    cd "$BACKEND_DIR"
    
    print_info "Installing backend dependencies..."
    npm install
    
    # Create or update .env file
    if [ ! -f "$BACKEND_DIR/.env" ]; then
        print_info "Creating .env file..."
        cat > "$BACKEND_DIR/.env" << EOF
PORT=$BACKEND_PORT
NODE_ENV=production
MONGO_URI=${MONGO_URI:-mongodb+srv://username:password@cluster.mongodb.net/travel_memory}
FRONTEND_URL=https://${DOMAIN:-yourdomain.com}
JWT_SECRET=${JWT_SECRET:-your_jwt_secret_here}
LOG_LEVEL=info
EOF
        print_info ".env file created (update with your values)"
    else
        print_info ".env file already exists"
    fi
    
    # Stop existing PM2 process if running
    pm2 stop "$PM2_APP_NAME" 2>/dev/null || true
    
    # Start backend with PM2
    print_info "Starting backend with PM2..."
    pm2 start index.js --name "$PM2_APP_NAME" --env production
    
    # Save PM2 configuration
    pm2 save
    
    print_success "Backend deployed successfully on port $BACKEND_PORT"
}

# Deploy Frontend
deploy_frontend() {
    print_header "Deploying Frontend"
    
    cd "$FRONTEND_DIR"
    
    print_info "Installing frontend dependencies..."
    npm install
    
    # Create or update .env file
    if [ ! -f "$FRONTEND_DIR/.env" ]; then
        print_info "Creating .env file..."
        cat > "$FRONTEND_DIR/.env" << EOF
REACT_APP_BACKEND_URL=https://${DOMAIN:-yourdomain.com}/api
REACT_APP_ENV=production
EOF
        print_info ".env file created (update with your values)"
    else
        print_info ".env file already exists"
    fi
    
    print_info "Building React application..."
    npm run build
    
    # Create Nginx configuration for frontend
    print_info "Configuring Nginx for frontend..."
    sudo tee /etc/nginx/sites-available/travelmemory-frontend > /dev/null << 'EOF'
server {
    listen 8080;
    server_name _;
    
    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html index.htm;
    
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
    
    location / {
        try_files $uri $uri/ /index.html;
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable Nginx site
    if [ ! -L /etc/nginx/sites-enabled/travelmemory-frontend ]; then
        sudo ln -s /etc/nginx/sites-available/travelmemory-frontend /etc/nginx/sites-enabled/
    fi
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl reload nginx
    
    print_success "Frontend deployed successfully on port $FRONTEND_PORT"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall (UFW)"
    
    if ! command -v ufw &> /dev/null; then
        sudo apt install -y ufw
    fi
    
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp     # SSH
    sudo ufw allow 80/tcp     # HTTP
    sudo ufw allow 443/tcp    # HTTPS
    sudo ufw allow 3000/tcp   # Backend (internal)
    sudo ufw allow 8080/tcp   # Frontend (internal)
    
    sudo ufw --force enable
    
    print_success "Firewall configured"
}

# Health check
health_check() {
    print_header "Health Check"
    
    print_info "Checking backend..."
    if curl -s http://localhost:$BACKEND_PORT/api/health > /dev/null; then
        print_success "Backend is responding"
    else
        print_error "Backend is not responding"
    fi
    
    print_info "Checking frontend..."
    if curl -s http://localhost:$FRONTEND_PORT > /dev/null; then
        print_success "Frontend is responding"
    else
        print_error "Frontend is not responding"
    fi
}

# Install SSL Certificate (Let's Encrypt)
install_ssl() {
    print_header "Installing SSL Certificate"
    
    if [ -z "$DOMAIN" ]; then
        print_error "DOMAIN not set. Skipping SSL installation."
        print_info "To install SSL later, run:"
        print_info "sudo apt install certbot python3-certbot-nginx"
        print_info "sudo certbot certonly --nginx -d yourdomain.com"
        return 1
    fi
    
    if command -v certbot &> /dev/null; then
        print_info "Certbot already installed"
    else
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    print_info "Obtaining SSL certificate for $DOMAIN..."
    sudo certbot certonly --nginx -d "$DOMAIN" -d "www.$DOMAIN" -n --agree-tos -m admin@"$DOMAIN"
    
    print_success "SSL certificate installed"
}

# Display deployment summary
show_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}Application Information:${NC}"
    echo "  Application Directory: $APP_DIR"
    echo "  Backend Port: $BACKEND_PORT"
    echo "  Frontend Port: $FRONTEND_PORT"
    echo "  PM2 App Name: $PM2_APP_NAME"
    echo ""
    
    echo -e "${GREEN}Service Status:${NC}"
    pm2 status
    echo ""
    
    echo -e "${GREEN}Nginx Status:${NC}"
    sudo systemctl status nginx --no-pager || true
    echo ""
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Update .env files with your configuration:"
    echo "     - $BACKEND_DIR/.env"
    echo "     - $FRONTEND_DIR/.env"
    echo ""
    echo "  2. Restart services:"
    echo "     pm2 restart $PM2_APP_NAME"
    echo "     sudo systemctl reload nginx"
    echo ""
    echo "  3. Configure domain and SSL:"
    echo "     DOMAIN=yourdomain.com bash $0"
    echo ""
    echo "  4. View logs:"
    echo "     pm2 logs $PM2_APP_NAME"
    echo "     sudo tail -f /var/log/nginx/error.log"
}

# Main deployment logic
main() {
    DEPLOY_TYPE=${1:-both}
    
    print_header "TravelMemory Application Deployment"
    print_info "Deployment Type: $DEPLOY_TYPE"
    print_info "Ubuntu User: ubuntu"
    
    case $DEPLOY_TYPE in
        backend)
            install_nodejs
            install_git
            install_pm2
            clone_repository
            deploy_backend
            ;;
        frontend)
            install_nodejs
            install_git
            install_nginx
            clone_repository
            deploy_frontend
            ;;
        both)
            update_system
            install_nodejs
            install_git
            install_nginx
            install_pm2
            clone_repository
            deploy_backend
            deploy_frontend
            configure_firewall
            ;;
        *)
            print_error "Invalid deployment type: $DEPLOY_TYPE"
            echo "Usage: bash deploy.sh [backend|frontend|both]"
            exit 1
            ;;
    esac
    
    health_check
    show_summary
    
    print_header "Deployment Complete ✓"
}

# Run main function
main "$@"
