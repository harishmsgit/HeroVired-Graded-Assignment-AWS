# TravelMemory EC2 Deployment Scripts - Complete Guide

## Overview

This guide explains how to use the deployment scripts to deploy the TravelMemory application on AWS EC2 instances.

### Available Scripts

1. **init.sh** - Initialize a fresh EC2 instance
2. **deploy.sh** - Full deployment (backend + frontend)
3. **deploy-backend.sh** - Backend deployment only
4. **deploy-frontend.sh** - Frontend deployment only
5. **manage.sh** - Manage running services

---

## Prerequisites

- AWS EC2 instance running Ubuntu 20.04 or 22.04 LTS
- SSH access to the instance
- Public/Elastic IP assigned (for frontend access)
- Security groups configured to allow ports 22, 80, 443
- Domain name (optional but recommended)

---

## Step 1: Launch EC2 Instance

### Create EC2 Instance
1. Go to AWS EC2 Dashboard
2. Click "Launch Instance"
3. Select "Ubuntu Server 22.04 LTS"
4. Instance type: t3.small (or larger)
5. Create/select security group:
   - SSH (22) from your IP
   - HTTP (80) from anywhere
   - HTTPS (443) from anywhere
   - Custom TCP 3000 from anywhere (backend)
6. Download key pair (.pem file)
7. Launch instance
8. Allocate Elastic IP (for consistent access)

### Connect to Instance

```bash
# Change permissions on key file
chmod 400 your-key.pem

# Connect to instance
ssh -i your-key.pem ubuntu@your-instance-ip
```

---

## Step 2: Initialize EC2 Instance

Once connected via SSH:

```bash
# Download initialization script
wget https://raw.githubusercontent.com/UnpredictablePrashant/TravelMemory/main/init.sh

# Make it executable
chmod +x init.sh

# Run initialization
bash init.sh
```

**What this does:**
- Updates system packages
- Installs Node.js 18
- Installs Nginx
- Installs PM2
- Clones the TravelMemory repository
- Configures firewall

---

## Step 3: Deploy Application

### Option A: Deploy Both Backend and Frontend

```bash
cd /home/ubuntu/TravelMemory

# Deploy everything
bash deploy.sh both
```

### Option B: Deploy Backend Only

```bash
cd /home/ubuntu/TravelMemory

bash deploy-backend.sh
```

### Option C: Deploy Frontend Only

```bash
cd /home/ubuntu/TravelMemory

bash deploy-frontend.sh
```

---

## Step 4: Configure Environment Variables

### Edit Backend Configuration

```bash
nano /home/ubuntu/TravelMemory/backend/.env
```

Update the following:

```env
PORT=3000
NODE_ENV=production
MONGO_URI=your_mongodb_connection_string
FRONTEND_URL=https://yourdomain.com
JWT_SECRET=your_strong_secret_key
LOG_LEVEL=info
```

**Save**: Press `Ctrl+X`, then `Y`, then `Enter`

### Restart Backend

```bash
pm2 restart travelmemory-backend
```

### Edit Frontend Configuration

```bash
nano /home/ubuntu/TravelMemory/frontend/.env
```

Update the following:

```env
REACT_APP_BACKEND_URL=https://yourdomain.com/api
REACT_APP_ENV=production
```

### Rebuild Frontend

```bash
cd /home/ubuntu/TravelMemory/frontend
npm run build
sudo systemctl reload nginx
```

---

## Step 5: Configure SSL Certificate

### Install Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### Obtain Certificate

```bash
sudo certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com
```

### Update Nginx Configuration

The SSL certificate will be at:
- Certificate: `/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
- Key: `/etc/letsencrypt/live/yourdomain.com/privkey.pem`

Add to Nginx configuration for HTTPS redirect.

---

## Step 6: Verify Deployment

### Check Service Status

```bash
# View all services
bash manage.sh status

# Or manually:
pm2 status                  # Backend
sudo systemctl status nginx # Frontend
```

### Health Check

```bash
bash manage.sh health
```

### View Logs

```bash
# Backend logs
pm2 logs travelmemory-backend

# Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Test Endpoints

```bash
# Backend health check
curl http://localhost:3000/api/health

# Frontend
curl http://localhost:8080
```

---

## Management Commands

### Start Services

```bash
bash manage.sh start
```

### Stop Services

```bash
bash manage.sh stop
```

### Restart Services

```bash
bash manage.sh restart
```

### View Current Status

```bash
bash manage.sh status
```

### View Logs

```bash
bash manage.sh logs
```

### Update Application

```bash
bash manage.sh update
```

Pulls latest code and rebuilds both applications.

### Create Backup

```bash
bash manage.sh backup
```

Creates compressed backup in `/home/ubuntu/backups/`

### Health Check

```bash
bash manage.sh health
```

Checks all services and disk space.

---

## Troubleshooting

### Backend not starting

```bash
# Check PM2 logs
pm2 logs travelmemory-backend

# Check if port is in use
sudo lsof -i :3000

# Restart
pm2 restart travelmemory-backend
```

### Frontend not loading

```bash
# Check Nginx status
sudo systemctl status nginx

# Check Nginx errors
sudo nginx -t
sudo systemctl reload nginx

# Check logs
sudo tail -f /var/log/nginx/error.log
```

### Cannot connect to database

```bash
# Check MongoDB URI in .env
cat backend/.env | grep MONGO_URI

# Test connection
# Update and restart backend
pm2 restart travelmemory-backend
```

### Port already in use

```bash
# Find what's using the port
sudo lsof -i :3000  # For backend
sudo lsof -i :8080  # For frontend

# Kill the process
sudo kill -9 <PID>
```

### Low disk space

```bash
# Check disk usage
df -h

# Clean up
bash manage.sh clean
```

---

## Directory Structure on EC2

```
/home/ubuntu/
├── TravelMemory/
│   ├── backend/
│   │   ├── index.js
│   │   ├── .env
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   └── package.json
│   │
│   ├── frontend/
│   │   ├── src/
│   │   ├── build/          # Built app (after npm run build)
│   │   ├── .env
│   │   └── package.json
│   │
│   └── *.sh                # Deployment scripts
│
└── backups/                # Backup files created by manage.sh
```

---

## Service Management with PM2

### View backend process

```bash
pm2 status
pm2 logs travelmemory-backend
```

### Restart backend after configuration change

```bash
pm2 restart travelmemory-backend
```

### Make PM2 start on reboot

```bash
pm2 startup
pm2 save
```

### Remove PM2 from startup

```bash
pm2 unstartup
```

---

## Nginx Configuration Locations

### Frontend configuration
```
/etc/nginx/sites-available/travelmemory-frontend
/etc/nginx/sites-enabled/travelmemory-frontend
```

### Check configuration
```bash
sudo nginx -t
```

### Reload after changes
```bash
sudo systemctl reload nginx
```

---

## Monitoring

### CPU and Memory Usage

```bash
# Real-time monitoring
top

# Or check PM2
pm2 monit
```

### Disk Space

```bash
df -h
du -sh /home/ubuntu/TravelMemory
```

### Network Ports

```bash
# Check what's listening
sudo netstat -tlnp

# Or with ss
ss -tlnp
```

---

## Database Backups

### MongoDB Backup

```bash
# If using MongoDB locally
mongodump --uri "mongodb+srv://user:pass@cluster.mongodb.net/travel_memory" \
          --out /home/ubuntu/backups/mongodb/

# Or use managed backups with MongoDB Atlas
```

---

## Auto-restart Services

The scripts already configure PM2 to auto-restart:

```bash
# This was done during init.sh
pm2 startup
pm2 save
```

Services will restart automatically if:
- Server reboots
- Process crashes
- Memory limit exceeded

---

## Security Considerations

### Update regularly

```bash
sudo apt update
sudo apt upgrade -y
```

### Check open ports

```bash
sudo ufw status
```

### View authentication logs

```bash
sudo tail -f /var/log/auth.log
```

### Check failed logins

```bash
sudo grep "Failed password" /var/log/auth.log | tail -10
```

---

## Performance Optimization

### Enable PM2 auto-restart on memory limit

```bash
pm2 start backend/index.js --name "travelmemory-backend" --max-memory-restart 500M
pm2 save
```

### Check Nginx worker processes

```bash
ps aux | grep nginx
```

### Monitor resource usage

```bash
# CPU usage
ps aux --sort=-%cpu | head -5

# Memory usage
ps aux --sort=-%mem | head -5
```

---

## Updating Application Code

### Pull latest changes

```bash
cd /home/ubuntu/TravelMemory
git pull origin main
```

### Or use the update command

```bash
bash manage.sh update
```

This will:
1. Pull latest code
2. Update backend dependencies
3. Restart backend
4. Update frontend dependencies
5. Rebuild frontend
6. Reload Nginx

---

## Backup and Recovery

### Create manual backup

```bash
bash manage.sh backup
```

### List backups

```bash
ls -lah /home/ubuntu/backups/
```

### Restore from backup

```bash
# Extract backup
cd /home/ubuntu
tar -xzf backups/travelmemory_backup_YYYYMMDD_HHMMSS.tar.gz

# Reinstall dependencies
cd TravelMemory/backend && npm install
cd ../frontend && npm install && npm run build

# Restart services
bash manage.sh restart
```

---

## Monitoring Logs

### Backend logs (latest 20 lines)

```bash
pm2 logs travelmemory-backend --lines 20
```

### Backend logs (live)

```bash
pm2 logs travelmemory-backend
```

### Nginx error logs

```bash
sudo tail -f /var/log/nginx/error.log
```

### Nginx access logs

```bash
sudo tail -f /var/log/nginx/access.log
```

---

## Troubleshooting Script Failures

### Make scripts executable

```bash
chmod +x /home/ubuntu/TravelMemory/*.sh
```

### Run with bash explicitly

```bash
bash deploy.sh both
bash deploy-backend.sh
bash deploy-frontend.sh
bash manage.sh status
```

### Check script syntax

```bash
bash -n script.sh
```

---

## Additional Resources

- **PM2 Documentation**: https://pm2.keymetrics.io/
- **Nginx Documentation**: https://nginx.org/en/docs/
- **Node.js Documentation**: https://nodejs.org/docs/
- **AWS EC2 Documentation**: https://docs.aws.amazon.com/ec2/

---

## Support Commands

### Get help with manage.sh

```bash
bash manage.sh
```

### Get server information

```bash
uname -a
lsb_release -a
node -v
npm -v
nginx -v
```

### Full system report

```bash
cat > /tmp/system_report.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
uname -a
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Service Status ==="
pm2 status
echo ""
echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager
EOF

bash /tmp/system_report.sh
```

---

## Next Steps

1. ✅ Launch EC2 instance
2. ✅ Run init.sh
3. ✅ Deploy with deploy.sh
4. ✅ Configure .env files
5. ✅ Set up SSL certificate
6. ✅ Configure domain DNS
7. ✅ Verify health with manage.sh
8. ✅ Set up monitoring
9. ✅ Configure backups
10. ✅ Go live!

---

**Version**: 1.0  
**Last Updated**: January 11, 2026  
**Status**: Production Ready
