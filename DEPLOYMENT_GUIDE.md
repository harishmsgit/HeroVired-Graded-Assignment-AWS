# TravelMemory Application - Deployment Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Backend Setup](#backend-setup)
4. [Frontend Setup](#frontend-setup)
5. [Nginx Reverse Proxy Configuration](#nginx-reverse-proxy-configuration)
6. [Load Balancer Setup](#load-balancer-setup)
7. [Domain Setup with Cloudflare](#domain-setup-with-cloudflare)
8. [Scaling the Application](#scaling-the-application)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

The TravelMemory application follows a modern, scalable architecture:

```
Internet/Users
    ↓
Cloudflare CDN (DNS & Security)
    ↓
AWS Route 53 (DNS Management)
    ↓
Load Balancer (ELB/ALB)
    ↓
┌─────────────────────────────────┐
│   EC2 Instance 1 (Frontend)     │
│   - Port 8080 (React App)       │
│   - Nginx Reverse Proxy         │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│   EC2 Instance 2 (Backend)      │
│   - Port 3000 (Node.js API)     │
│   - Port 3001 (Backup Instance) │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│   Database (MongoDB/RDS)        │
│   - Primary Replica Set         │
│   - Backup & Recovery           │
└─────────────────────────────────┘
```

---

## Prerequisites

Before beginning the deployment process, ensure you have:

### Required Software
- **Node.js** (v16 or higher)
- **npm** or **yarn** (Node package managers)
- **Nginx** (for reverse proxy)
- **MongoDB** or **PostgreSQL** (database)
- **Git** (for version control)
- **PM2** (for process management)

### AWS Requirements
- EC2 instances (Ubuntu 20.04 LTS or 22.04 LTS)
- VPC with proper security groups
- Elastic Load Balancer (ELB/ALB)
- RDS or MongoDB Atlas
- Route 53 (DNS)

### Domain & SSL
- Custom domain name
- Cloudflare account
- SSL/TLS certificate (auto-generated or purchased)

---

## Backend Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/backend
```

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Configure Environment Variables
Update the `.env` file with your actual values:

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Database Configuration (MongoDB)
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/travel_memory?retryWrites=true&w=majority

# Database Configuration (PostgreSQL - optional)
# DATABASE_URL=postgresql://db_user:db_pass@db-hostname:5432/travel_memory

# CORS Configuration
FRONTEND_URL=https://yourdomain.com

# JWT Secret for Authentication
JWT_SECRET=your_strong_jwt_secret_key_here

# Environment Specific Settings
LOG_LEVEL=info
```

### Step 4: Test Backend Locally
```bash
npm start
```

The backend should be accessible at `http://localhost:3000`

### Step 5: Start Backend with PM2 (Production)
```bash
npm install -g pm2

# Start the application
pm2 start index.js --name "travelmemory-backend"

# Make it restart on system reboot
pm2 startup
pm2 save
```

---

## Frontend Setup

### Step 1: Navigate to Frontend Directory
```bash
cd TravelMemory/frontend
```

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Configure Environment Variables
Update the `.env` file:

```env
# Frontend Environment Configuration
REACT_APP_BACKEND_URL=https://api.yourdomain.com
REACT_APP_ENV=production
```

### Step 4: Build for Production
```bash
npm run build
```

This creates an optimized build in the `build/` directory.

### Step 5: Serve Frontend with Nginx
Copy the build to a web directory:
```bash
sudo cp -r build/* /var/www/travelmemory/
```

Configure Nginx to serve the React app (see Nginx configuration below).

---

## Nginx Reverse Proxy Configuration

### Step 1: Install Nginx
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 2: Create Nginx Configuration
Create `/etc/nginx/sites-available/travelmemory`:

```nginx
upstream backend {
    server localhost:3000;
    server localhost:3001;  # Backup instance
}

upstream frontend {
    server localhost:8080;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/ssl/certs/yourdomain.com.crt;
    ssl_certificate_key /etc/ssl/private/yourdomain.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    add_header Strict-Transport-Security "max-age=31536000" always;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;

    # Frontend
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### Step 3: Enable Configuration
```bash
sudo ln -s /etc/nginx/sites-available/travelmemory /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl reload nginx
```

---

## Load Balancer Setup

### AWS Elastic Load Balancer (ALB/ELB) Configuration

#### Step 1: Create Target Groups
1. Go to AWS EC2 → Target Groups
2. Create "backend-targets" on port 3000
3. Create "frontend-targets" on port 8080
4. Add EC2 instances to respective target groups
5. Configure health checks:
   - Backend: `/api/health` (interval: 30s, healthy threshold: 2)
   - Frontend: `/` (interval: 30s, healthy threshold: 2)

#### Step 2: Create Load Balancer
1. Go to AWS EC2 → Load Balancers
2. Create Application Load Balancer (ALB)
3. Configure listeners:
   - Port 80 (HTTP) → Redirect to HTTPS
   - Port 443 (HTTPS) → Forward to target groups
4. Attach SSL certificate

#### Step 3: Routing Rules
```
HTTP/HTTPS://yourdomain.com/api/* → backend-targets:3000
HTTP/HTTPS://yourdomain.com/* → frontend-targets:8080
```

---

## Domain Setup with Cloudflare

### Step 1: Add Domain to Cloudflare
1. Log in to Cloudflare account
2. Click "Add Site" and enter your domain
3. Cloudflare scans for existing DNS records
4. Update nameservers at your registrar to use Cloudflare's nameservers

### Step 2: Configure DNS Records

#### A Record (for EC2 Frontend Instance)
```
Type: A
Name: @
IPv4 Address: <Your EC2 Instance Public IP>
TTL: Auto
Proxy Status: Proxied (Orange Cloud)
```

#### CNAME Record (for Load Balancer)
```
Type: CNAME
Name: api
Target: <Load Balancer DNS Name>
TTL: Auto
Proxy Status: Proxied (Orange Cloud)
```

Example:
```
Type: CNAME
Name: api
Target: travelmemory-alb-1234567890.us-east-1.elb.amazonaws.com
```

### Step 3: SSL/TLS Configuration
1. Go to SSL/TLS settings in Cloudflare
2. Set SSL mode to "Full (Strict)"
3. Configure page rules for caching and performance

### Step 4: Firewall & Security Rules
1. Set DDoS protection: "High"
2. Configure rate limiting if needed
3. Enable bot management for production

---

## Scaling the Application

### Backend Scaling

#### Multiple Instance Setup
1. Launch 2-3 additional EC2 instances (t3.medium or similar)
2. Install Node.js, npm, and dependencies on each instance
3. Deploy backend code to each instance
4. Configure different ports (3000, 3001, 3002)
5. Add all instances to load balancer target group

#### Start Multiple Backend Instances
```bash
# Instance 1
PORT=3000 pm2 start index.js --name "backend-1"

# Instance 2 (on different EC2)
PORT=3001 pm2 start index.js --name "backend-2"

# Instance 3
PORT=3002 pm2 start index.js --name "backend-3"
```

### Frontend Scaling

#### Multiple Frontend Instances
1. Launch 2 additional EC2 instances for frontend
2. Build React app on each instance
3. Configure Nginx on ports 8080, 8081
4. Add instances to frontend target group

#### Configure Multiple Frontend Ports
```bash
# Instance 1
PORT=8080 npm start

# Instance 2
PORT=8081 npm start
```

### Database Scaling

#### MongoDB Replica Set (High Availability)
```bash
# Initialize replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "primary-node:27017" },
    { _id: 1, host: "secondary-node:27017" },
    { _id: 2, host: "arbiter-node:27017" }
  ]
})
```

#### Database Backups
```bash
# Daily backup using mongodump
0 2 * * * mongodump --out /backups/mongo-$(date +\%Y\%m\%d)
```

---

## Security Considerations

### 1. Network Security
- **Security Groups**: Restrict inbound traffic
  - Frontend: Allow ports 80, 443
  - Backend: Allow only from Load Balancer
  - Database: Allow only from Backend instances

### 2. Data Encryption
- **In Transit**: Use HTTPS/TLS 1.2+
- **At Rest**: Enable database encryption
- **Credentials**: Use AWS Secrets Manager for sensitive data

### 3. Application Security
- Keep dependencies updated: `npm audit fix`
- Use helmet for HTTP headers: `npm install helmet`
- Implement rate limiting
- Validate all user inputs
- Use JWT for authentication with strong secrets

### 4. Access Control
- Implement role-based access control (RBAC)
- Use IAM roles for EC2 instances
- Enable MFA for AWS accounts
- Regular security audits

### 5. Monitoring & Logging
- CloudWatch for logs and metrics
- Set up alarms for critical events
- Enable VPC Flow Logs
- Use X-Ray for application tracing

---

## Troubleshooting

### Backend Not Responding
```bash
# Check if backend is running
pm2 status

# View logs
pm2 logs travelmemory-backend

# Restart backend
pm2 restart travelmemory-backend
```

### Frontend Can't Connect to Backend
1. Verify `.env` file has correct `REACT_APP_BACKEND_URL`
2. Check CORS settings in backend
3. Verify load balancer routing rules
4. Check security group rules

### Nginx Configuration Issues
```bash
# Test nginx configuration
sudo nginx -t

# View nginx error logs
sudo tail -f /var/log/nginx/error.log

# Reload nginx
sudo systemctl reload nginx
```

### Database Connection Failed
1. Verify `MONGO_URI` or `DATABASE_URL` in `.env`
2. Check database firewall rules
3. Verify credentials
4. Test connection manually

### SSL Certificate Issues
1. Verify certificate path in nginx config
2. Check certificate validity: `openssl x509 -in cert.crt -text -noout`
3. Ensure certificate includes domain and www subdomain

---

## Performance Optimization Tips

1. **Frontend**:
   - Enable code splitting in React
   - Use React.lazy() for components
   - Optimize images and assets
   - Implement service workers

2. **Backend**:
   - Use caching (Redis)
   - Optimize database queries
   - Implement pagination for APIs
   - Use connection pooling

3. **Infrastructure**:
   - Enable gzip compression in Nginx
   - Use CDN for static assets (CloudFront)
   - Implement database read replicas
   - Use auto-scaling policies

---

## Monitoring Checklist

- [ ] Backend health: `/api/health` endpoint responding
- [ ] Frontend loads successfully
- [ ] Database connections stable
- [ ] SSL certificate valid
- [ ] Load balancer healthy
- [ ] No error logs in CloudWatch
- [ ] API response times acceptable
- [ ] Database query performance optimal

---

## Support & Maintenance

### Regular Maintenance Tasks
- Weekly: Check logs and alerts
- Monthly: Update dependencies and security patches
- Quarterly: Performance review and optimization
- Annually: Security audit and disaster recovery testing

For issues, check the troubleshooting section or contact the development team.
