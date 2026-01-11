#!/bin/bash

# TravelMemory Ecosystem Management Script
# Manage all services: backend, frontend, nginx, database
# Usage: bash manage.sh [start|stop|restart|status|logs|update]

set -e

PM2_APP_NAME="travelmemory-backend"
BACKEND_PORT=3000
FRONTEND_PORT=8080
APP_DIR="/home/ubuntu/TravelMemory"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    echo "Usage: bash manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show status of all services"
    echo "  logs        - Show logs (backend, frontend, nginx)"
    echo "  update      - Pull latest code and rebuild"
    echo "  health      - Health check all services"
    echo "  backup      - Backup application data"
    echo "  clean       - Clean build and node_modules"
    echo "  env         - Edit environment variables"
    echo ""
}

start_services() {
    echo -e "${YELLOW}Starting all services...${NC}"
    
    # Start backend
    echo "Starting backend..."
    pm2 start "$PM2_APP_NAME" 2>/dev/null || pm2 start "$APP_DIR/backend/index.js" --name "$PM2_APP_NAME"
    
    # Start Nginx
    echo "Starting Nginx..."
    sudo systemctl start nginx
    
    echo -e "${GREEN}✓ All services started${NC}"
}

stop_services() {
    echo -e "${YELLOW}Stopping all services...${NC}"
    
    # Stop backend
    echo "Stopping backend..."
    pm2 stop "$PM2_APP_NAME" 2>/dev/null || true
    
    # Stop Nginx
    echo "Stopping Nginx..."
    sudo systemctl stop nginx
    
    echo -e "${GREEN}✓ All services stopped${NC}"
}

restart_services() {
    echo -e "${YELLOW}Restarting all services...${NC}"
    
    # Restart backend
    echo "Restarting backend..."
    pm2 restart "$PM2_APP_NAME"
    
    # Reload Nginx
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
    
    echo -e "${GREEN}✓ All services restarted${NC}"
}

show_status() {
    echo -e "${YELLOW}Service Status:${NC}"
    echo ""
    
    echo "Backend (PM2):"
    pm2 status | grep "$PM2_APP_NAME" || echo "  Not running"
    echo ""
    
    echo "Nginx:"
    sudo systemctl is-active nginx && echo "  Active (running)" || echo "  Inactive"
    echo ""
    
    echo "Port Status:"
    echo -n "  Backend (port $BACKEND_PORT): "
    curl -s http://localhost:$BACKEND_PORT/api/health > /dev/null && echo "✓ Responding" || echo "✗ Not responding"
    
    echo -n "  Frontend (port $FRONTEND_PORT): "
    curl -s http://localhost:$FRONTEND_PORT > /dev/null && echo "✓ Responding" || echo "✗ Not responding"
}

show_logs() {
    echo -e "${YELLOW}Recent Logs:${NC}"
    echo ""
    
    echo "Backend logs (last 20 lines):"
    pm2 logs "$PM2_APP_NAME" --lines 20 2>/dev/null || echo "  No logs available"
    echo ""
    
    echo -e "${YELLOW}To view live logs:${NC}"
    echo "  Backend: pm2 logs $PM2_APP_NAME"
    echo "  Nginx: sudo tail -f /var/log/nginx/error.log"
    echo "  Nginx Access: sudo tail -f /var/log/nginx/access.log"
}

update_application() {
    echo -e "${YELLOW}Updating application...${NC}"
    
    cd "$APP_DIR"
    
    echo "Pulling latest code..."
    git pull origin main
    
    echo "Updating backend..."
    cd "$APP_DIR/backend"
    npm install
    pm2 restart "$PM2_APP_NAME"
    
    echo "Updating frontend..."
    cd "$APP_DIR/frontend"
    npm install
    npm run build
    sudo systemctl reload nginx
    
    echo -e "${GREEN}✓ Application updated${NC}"
}

health_check() {
    echo -e "${YELLOW}Health Check:${NC}"
    echo ""
    
    # Check backend
    echo -n "Backend health: "
    if curl -s http://localhost:$BACKEND_PORT/api/health > /dev/null 2>&1; then
        BACKEND_HEALTH=$(curl -s http://localhost:$BACKEND_PORT/api/health)
        echo -e "${GREEN}✓${NC}"
        echo "  Response: $BACKEND_HEALTH"
    else
        echo -e "${RED}✗${NC}"
    fi
    echo ""
    
    # Check frontend
    echo -n "Frontend health: "
    if curl -s http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    echo ""
    
    # Check disk space
    echo "Disk Space:"
    df -h | grep -E "^/dev" | awk '{print "  " $0}'
}

backup_data() {
    echo -e "${YELLOW}Creating backup...${NC}"
    
    BACKUP_DIR="/home/ubuntu/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="travelmemory_backup_$TIMESTAMP.tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    echo "Backing up application files..."
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
        --exclude=node_modules \
        --exclude=build \
        --exclude=.git \
        -C /home/ubuntu TravelMemory
    
    echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/$BACKUP_FILE${NC}"
    
    # Show backup size
    ls -lh "$BACKUP_DIR/$BACKUP_FILE" | awk '{print "  Size: " $5}'
    
    # Keep only last 5 backups
    echo "Cleaning old backups..."
    cd "$BACKUP_DIR" && ls -t *.tar.gz | tail -n +6 | xargs -r rm
    echo "Kept last 5 backups"
}

clean_build() {
    echo -e "${YELLOW}Cleaning build files...${NC}"
    
    echo "Cleaning backend..."
    cd "$APP_DIR/backend"
    rm -rf node_modules package-lock.json
    
    echo "Cleaning frontend..."
    cd "$APP_DIR/frontend"
    rm -rf node_modules build package-lock.json
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

edit_env() {
    echo -e "${YELLOW}Edit Environment Variables${NC}"
    echo ""
    echo "1. Edit backend configuration"
    echo "2. Edit frontend configuration"
    echo "3. Cancel"
    echo ""
    read -p "Select option (1-3): " choice
    
    case $choice in
        1)
            nano "$APP_DIR/backend/.env"
            echo "Restarting backend..."
            pm2 restart "$PM2_APP_NAME"
            ;;
        2)
            nano "$APP_DIR/frontend/.env"
            echo "Rebuilding frontend..."
            cd "$APP_DIR/frontend"
            npm run build
            sudo systemctl reload nginx
            ;;
        3)
            echo "Cancelled"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

main() {
    COMMAND=${1:-status}
    
    case $COMMAND in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        update)
            update_application
            ;;
        health)
            health_check
            ;;
        backup)
            backup_data
            ;;
        clean)
            clean_build
            ;;
        env)
            edit_env
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
