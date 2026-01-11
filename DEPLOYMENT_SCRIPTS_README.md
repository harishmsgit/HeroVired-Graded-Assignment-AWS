# AWS EC2 Deployment Scripts - Quick Reference

## 📦 Deployment Scripts Created

This package includes everything needed to deploy TravelMemory on AWS EC2.

---

## 🚀 Quick Start

### 1. Launch EC2 Instance
- Ubuntu 22.04 LTS
- t3.small or larger
- Security groups: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- Create Elastic IP

### 2. Connect and Initialize

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@your-ip

# Download and run init script
wget https://raw.githubusercontent.com/UnpredictablePrashant/TravelMemory/main/init.sh
bash init.sh
```

### 3. Deploy Application

```bash
cd /home/ubuntu/TravelMemory

# Deploy everything (backend + frontend)
bash deploy.sh both

# Or deploy separately
bash deploy-backend.sh    # Backend only
bash deploy-frontend.sh   # Frontend only
```

### 4. Configure

```bash
# Edit backend configuration
nano backend/.env

# Edit frontend configuration
nano frontend/.env

# Restart services
bash manage.sh restart
```

### 5. Verify

```bash
# Check all services
bash manage.sh health

# View logs
bash manage.sh logs
```

---

## 📋 Scripts Overview

### init.sh
**Purpose**: Initialize fresh EC2 instance
**Runtime**: ~5-10 minutes
**What it does**:
- Updates system packages
- Installs Node.js 18
- Installs Nginx
- Installs PM2
- Clones repository
- Configures firewall

**Usage**:
```bash
bash init.sh
```

### deploy.sh
**Purpose**: Full application deployment
**Runtime**: ~10-15 minutes
**What it does**:
- Runs init.sh steps if needed
- Installs backend dependencies
- Creates backend .env
- Starts backend with PM2
- Installs frontend dependencies
- Creates frontend .env
- Builds React app
- Configures Nginx

**Usage**:
```bash
bash deploy.sh both         # Both frontend and backend
bash deploy.sh backend      # Backend only
bash deploy.sh frontend     # Frontend only
```

### deploy-backend.sh
**Purpose**: Deploy backend only
**Runtime**: ~3-5 minutes
**What it does**:
- Installs Node.js if needed
- Installs dependencies
- Creates .env file
- Starts with PM2
- Configures auto-restart

**Usage**:
```bash
bash deploy-backend.sh
```

### deploy-frontend.sh
**Purpose**: Deploy frontend only
**Runtime**: ~5-8 minutes
**What it does**:
- Installs Node.js if needed
- Installs dependencies
- Creates .env file
- Builds React app
- Configures Nginx
- Reloads Nginx

**Usage**:
```bash
bash deploy-frontend.sh
```

### manage.sh
**Purpose**: Manage running services
**Runtime**: Varies by command
**Available commands**:
- `start` - Start all services
- `stop` - Stop all services
- `restart` - Restart all services
- `status` - Show service status
- `logs` - Display logs
- `update` - Pull latest code
- `health` - Health check
- `backup` - Create backup
- `clean` - Clean build files
- `env` - Edit configuration

**Usage**:
```bash
bash manage.sh status
bash manage.sh logs
bash manage.sh update
```

---

## 📁 File Structure After Deployment

```
EC2 Instance (/home/ubuntu)
│
├── TravelMemory/
│   ├── backend/
│   │   ├── index.js
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── .env              ← UPDATE THIS
│   │   ├── node_modules/
│   │   └── package.json
│   │
│   ├── frontend/
│   │   ├── src/
│   │   ├── public/
│   │   ├── build/            ← Production build
│   │   ├── .env              ← UPDATE THIS
│   │   ├── node_modules/
│   │   └── package.json
│   │
│   ├── init.sh               ← Initialize instance
│   ├── deploy.sh             ← Full deployment
│   ├── deploy-backend.sh     ← Backend only
│   ├── deploy-frontend.sh    ← Frontend only
│   └── manage.sh             ← Service management
│
└── backups/                  ← Automatic backups
    └── travelmemory_backup_*.tar.gz
```

---

## 🔧 Configuration Files

### Backend Configuration (.env)
```
PORT=3000
NODE_ENV=production
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/db
FRONTEND_URL=https://yourdomain.com
JWT_SECRET=your_strong_secret
LOG_LEVEL=info
```

**Location**: `/home/ubuntu/TravelMemory/backend/.env`

### Frontend Configuration (.env)
```
REACT_APP_BACKEND_URL=https://api.yourdomain.com
REACT_APP_ENV=production
```

**Location**: `/home/ubuntu/TravelMemory/frontend/.env`

---

## 🚦 Service Ports

| Service | Port | Type | Access |
|---------|------|------|--------|
| Backend API | 3000 | Internal | PM2 managed |
| Frontend Web | 8080 | Internal | Nginx proxied |
| Nginx HTTP | 80 | Public | Internet |
| Nginx HTTPS | 443 | Public | Internet |

---

## 📊 Command Reference

### Check Status
```bash
# All services
bash manage.sh status

# PM2 processes
pm2 status

# Nginx
sudo systemctl status nginx

# Ports
sudo lsof -i -P -n | grep LISTEN
```

### View Logs
```bash
# Backend (live)
pm2 logs travelmemory-backend

# Backend (last 20 lines)
pm2 logs travelmemory-backend --lines 20

# Nginx errors
sudo tail -f /var/log/nginx/error.log

# Nginx access
sudo tail -f /var/log/nginx/access.log
```

### Restart Services
```bash
# All services
bash manage.sh restart

# Backend only
pm2 restart travelmemory-backend

# Frontend (Nginx)
sudo systemctl reload nginx

# Or individually via manage.sh
bash manage.sh start
bash manage.sh stop
```

### Update Application
```bash
# Full update (pull + rebuild)
bash manage.sh update

# Manual update
cd /home/ubuntu/TravelMemory
git pull origin main
cd backend && npm install && pm2 restart travelmemory-backend
cd ../frontend && npm install && npm run build && sudo systemctl reload nginx
```

### Backup Data
```bash
# Create backup
bash manage.sh backup

# List backups
ls -lah /home/ubuntu/backups/

# Restore backup
cd /home/ubuntu
tar -xzf backups/travelmemory_backup_*.tar.gz
bash manage.sh restart
```

---

## 🔒 Security Setup

### Configure Firewall
```bash
# Already configured by init.sh
sudo ufw status

# Add custom rule
sudo ufw allow 3000/tcp
```

### Install SSL Certificate
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renew
sudo systemctl enable certbot.timer
```

### Update Nginx for HTTPS
Create `/etc/nginx/sites-available/travelmemory-proxy`:
```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # Proxy to backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Proxy to frontend
    location / {
        proxy_pass http://localhost:8080;
    }
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

---

## 🐛 Troubleshooting

### Backend not starting
```bash
# Check logs
pm2 logs travelmemory-backend

# Check if port is in use
sudo lsof -i :3000

# Restart
pm2 restart travelmemory-backend
```

### Frontend not loading
```bash
# Test Nginx
sudo nginx -t
sudo systemctl reload nginx

# Check build exists
ls -la /home/ubuntu/TravelMemory/frontend/build/

# Rebuild
cd /home/ubuntu/TravelMemory/frontend
npm run build
```

### Database connection error
```bash
# Check MongoDB URI
cat /home/ubuntu/TravelMemory/backend/.env | grep MONGO_URI

# Update and restart
pm2 restart travelmemory-backend

# Check connection
pm2 logs travelmemory-backend
```

### Cannot access instance
```bash
# Check security group allows SSH (port 22)
# Check key file permissions
chmod 400 your-key.pem

# Check instance is running
aws ec2 describe-instances --region us-east-1
```

---

## 📈 Scaling & Performance

### Add another backend instance
```bash
# Start on different port
PORT=3001 pm2 start backend/index.js --name "travelmemory-backend-2"
pm2 save

# Update Nginx upstream
sudo nano /etc/nginx/sites-available/travelmemory-proxy
```

### Monitor resources
```bash
# Real-time
top

# PM2 monitoring
pm2 monit

# Disk usage
df -h
du -sh /home/ubuntu/TravelMemory
```

### Optimize performance
```bash
# Enable gzip in Nginx (already configured)
# Enable caching (configure in Nginx)
# Use CloudFront (AWS)
# Enable database indexing (MongoDB)
```

---

## 📞 Support Commands

### System Information
```bash
uname -a
lsb_release -a
node -v
npm -v
nginx -v
git --version
```

### EC2 Metadata
```bash
curl http://169.254.169.254/latest/meta-data/public-ipv4
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/instance-type
```

### Network Diagnostics
```bash
# DNS resolution
nslookup yourdomain.com

# Connection test
curl -I https://yourdomain.com

# Port scan
sudo nmap -p 80,443,3000,8080 localhost
```

---

## ✅ Post-Deployment Checklist

- [ ] EC2 instance launched and running
- [ ] Elastic IP assigned
- [ ] Security groups configured
- [ ] init.sh executed successfully
- [ ] deploy.sh completed
- [ ] Backend .env configured with MongoDB URI
- [ ] Frontend .env configured with backend URL
- [ ] Health check passing: `bash manage.sh health`
- [ ] Backend responding: `curl http://localhost:3000/api/health`
- [ ] Frontend loading: `curl http://localhost:8080`
- [ ] Nginx configured and reloaded
- [ ] SSL certificate obtained
- [ ] Domain DNS configured
- [ ] HTTPS redirect working
- [ ] Logs monitored: `pm2 logs`
- [ ] Backups scheduled
- [ ] Monitoring configured

---

## 🎯 Next Steps

1. **Day 1**: Deploy and verify
2. **Day 2**: Configure SSL and domain
3. **Day 3**: Set up monitoring and alerting
4. **Day 4**: Load testing
5. **Day 5**: Production go-live

---

## 📚 Additional Resources

- **EC2 Guide**: See `EC2_DEPLOYMENT_GUIDE.md`
- **Full Guide**: See `DEPLOYMENT_GUIDE.md`
- **Setup Guide**: See `SETUP_GUIDE.md`
- **Architecture**: See `ARCHITECTURE_DIAGRAM_GUIDE.md`

---

**Version**: 1.0  
**Created**: January 11, 2026  
**Status**: Ready for Deployment

---

## 🚀 Ready to Deploy!

All scripts are production-ready. Follow the Quick Start section above to get started.

For questions, refer to `EC2_DEPLOYMENT_GUIDE.md` for detailed instructions.
