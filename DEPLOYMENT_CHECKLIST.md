# TravelMemory Deployment Checklist

## Pre-Deployment Verification

### Code Quality
- [ ] Run `npm audit` on both frontend and backend
- [ ] Fix all critical and high-severity vulnerabilities
- [ ] Run linter if configured: `npm run lint`
- [ ] All tests passing (if available)
- [ ] Code reviewed by team member
- [ ] No console.log statements left in production code
- [ ] No sensitive data hardcoded

### Configuration Verification
- [ ] Backend `.env` configured with production values
- [ ] Frontend `.env` configured with production backend URL
- [ ] Database connection string verified
- [ ] JWT secret is strong and unique
- [ ] CORS origin URL matches domain
- [ ] All required environment variables defined

### Local Testing
- [ ] Backend starts without errors
- [ ] Health check endpoint responds: `GET /api/health`
- [ ] Frontend builds successfully: `npm run build`
- [ ] Frontend can reach backend API
- [ ] All main features tested locally
- [ ] No CORS errors in browser console
- [ ] Database operations working correctly

---

## AWS Infrastructure Setup

### VPC & Security
- [ ] VPC created with proper CIDR block
- [ ] Public subnet for frontend (20.0.1.0/24)
- [ ] Private subnet for backend (20.0.2.0/24)
- [ ] Private subnet for database (20.0.3.0/24)
- [ ] Internet Gateway attached to VPC
- [ ] NAT Gateway for private subnets
- [ ] Route tables configured correctly

### Security Groups
- [ ] Frontend SG: Allow 80, 443 from anywhere
- [ ] Backend SG: Allow 3000 from Frontend SG only
- [ ] Database SG: Allow 27017 from Backend SG only
- [ ] All rules reviewed and documented

### EC2 Instances
- [ ] Frontend instances created (Ubuntu 20.04/22.04 LTS)
  - [ ] Instance 1 launched and configured
  - [ ] Instance 2 launched and configured
  - [ ] SSH key pairs saved securely
  - [ ] Elastic IPs assigned (if needed)
  
- [ ] Backend instances created
  - [ ] Instance 1 launched and configured (Port 3000)
  - [ ] Instance 2 launched and configured (Port 3001)
  - [ ] Instance 3 launched and configured (Port 3002)
  - [ ] SSH keys saved securely

### Database Setup
- [ ] MongoDB Atlas account created (or RDS provisioned)
- [ ] Cluster created and configured
- [ ] Database user created with strong password
- [ ] IP whitelist configured (backend server IPs)
- [ ] Connection string obtained
- [ ] Backup enabled
- [ ] Monitoring enabled

### Elastic Load Balancer
- [ ] ALB created in production account
- [ ] Target Group 1 created for frontend (port 8080)
- [ ] Target Group 2 created for backend (port 3000)
- [ ] Health checks configured
  - [ ] Frontend path: `/`
  - [ ] Backend path: `/api/health`
  - [ ] Interval: 30 seconds
  - [ ] Healthy threshold: 2
  - [ ] Unhealthy threshold: 3

- [ ] Listener configured for port 80 (redirect to 443)
- [ ] Listener configured for port 443 (SSL/TLS)
- [ ] SSL certificate uploaded or ACM certificate created
- [ ] Routing rules configured
- [ ] Stickiness disabled (if using multiple instances)

---

## Application Deployment

### Backend Deployment
- [ ] SSH into backend instance
- [ ] Install Node.js: `sudo apt install nodejs npm -y`
- [ ] Clone repository: `git clone <repo-url>`
- [ ] Navigate to backend: `cd TravelMemory/backend`
- [ ] Install dependencies: `npm install`
- [ ] Create `.env` file with production values
- [ ] Test locally: `npm start`
- [ ] Verify API responds: `curl http://localhost:3000/api/health`
- [ ] Install PM2: `npm install -g pm2`
- [ ] Start with PM2: `pm2 start index.js --name "backend"`
- [ ] Make PM2 persistent: `pm2 startup` and `pm2 save`
- [ ] Verify process running: `pm2 status`
- [ ] Check logs: `pm2 logs`

### Frontend Deployment
- [ ] SSH into frontend instance
- [ ] Install Node.js and npm
- [ ] Clone repository
- [ ] Navigate to frontend: `cd TravelMemory/frontend`
- [ ] Install dependencies: `npm install`
- [ ] Create `.env` file with production backend URL
- [ ] Build React app: `npm run build`
- [ ] Copy build to web directory: `sudo cp -r build/* /var/www/html/`
- [ ] Verify files copied correctly

### Nginx Setup
- [ ] Install Nginx: `sudo apt install nginx -y`
- [ ] Copy `nginx.conf` to `/etc/nginx/sites-available/travelmemory`
- [ ] Update server names and paths in config
- [ ] Create symlink: `sudo ln -s /etc/nginx/sites-available/travelmemory /etc/nginx/sites-enabled/`
- [ ] Test config: `sudo nginx -t`
- [ ] Start Nginx: `sudo systemctl start nginx`
- [ ] Enable on boot: `sudo systemctl enable nginx`
- [ ] Verify running: `sudo systemctl status nginx`

### SSL Certificate
- [ ] Obtain SSL certificate (Let's Encrypt or purchased)
- [ ] Place certificate files in `/etc/ssl/certs/` and `/etc/ssl/private/`
- [ ] Update certificate paths in nginx.conf
- [ ] Test certificate: `openssl x509 -in cert.crt -text -noout`
- [ ] Reload Nginx: `sudo systemctl reload nginx`
- [ ] Verify HTTPS working: `curl https://yourdomain.com`

---

## Domain & DNS Configuration

### Cloudflare Setup
- [ ] Create Cloudflare account
- [ ] Add domain to Cloudflare
- [ ] Scan for existing DNS records
- [ ] Update nameservers at registrar to Cloudflare nameservers
- [ ] Wait for DNS propagation (up to 48 hours)
- [ ] Verify nameservers updated: `nslookup yourdomain.com`

### DNS Records
- [ ] Create A record:
  - [ ] Name: @ (root)
  - [ ] Type: A
  - [ ] IPv4 Address: <EC2 Frontend Instance Public IP>
  - [ ] TTL: Auto
  - [ ] Proxy: Proxied (Orange Cloud)

- [ ] Create CNAME record:
  - [ ] Name: api
  - [ ] Type: CNAME
  - [ ] Target: <Load Balancer DNS Name>
  - [ ] TTL: Auto
  - [ ] Proxy: Proxied (Orange Cloud)

- [ ] Optional - Create WWW subdomain:
  - [ ] Name: www
  - [ ] Type: CNAME
  - [ ] Target: @
  - [ ] TTL: Auto

### Cloudflare Settings
- [ ] SSL/TLS mode: Full (Strict)
- [ ] Always use HTTPS: Enabled
- [ ] Auto HTTPS Rewrites: Enabled
- [ ] Brotli compression: Enabled
- [ ] Caching level: Standard
- [ ] Browser cache TTL: 4 hours
- [ ] DDoS protection: High
- [ ] Rate limiting configured (if needed)

### Test DNS
- [ ] Test A record: `nslookup yourdomain.com`
- [ ] Test CNAME: `nslookup api.yourdomain.com`
- [ ] Verify IP matches EC2 instance
- [ ] Verify CNAME resolves to ALB DNS

---

## Load Balancer Configuration

### Target Groups Setup
- [ ] Frontend target group created
  - [ ] Name: frontend-targets
  - [ ] Port: 8080
  - [ ] Protocol: HTTP
  - [ ] Health check path: /
  - [ ] EC2 instances registered

- [ ] Backend target group created
  - [ ] Name: backend-targets
  - [ ] Port: 3000
  - [ ] Protocol: HTTP
  - [ ] Health check path: /api/health
  - [ ] EC2 instances registered

- [ ] Verify all instances healthy (green status)
- [ ] Monitor target group metrics

### ALB Listeners
- [ ] HTTP listener (port 80)
  - [ ] Default action: Redirect to HTTPS
  - [ ] Status code: 301

- [ ] HTTPS listener (port 443)
  - [ ] SSL certificate: Selected/uploaded
  - [ ] Default action: Forward to frontend targets
  - [ ] Rules configured:
    - [ ] Path /api/* → backend targets
    - [ ] Path /* → frontend targets

### Load Balancer Testing
- [ ] Test frontend: `curl http://yourdomain.com` (should redirect)
- [ ] Test HTTPS: `curl https://yourdomain.com`
- [ ] Test API: `curl https://yourdomain.com/api/health`
- [ ] Test from multiple clients
- [ ] Verify load distribution

---

## Monitoring & Logging Setup

### CloudWatch
- [ ] CloudWatch agent installed on EC2 instances
- [ ] Log groups created for:
  - [ ] Backend application logs
  - [ ] Frontend access logs
  - [ ] Nginx logs
  - [ ] System logs

- [ ] Metrics being collected:
  - [ ] CPU utilization
  - [ ] Memory usage
  - [ ] Disk I/O
  - [ ] Network throughput

- [ ] Dashboards created:
  - [ ] Overall system health
  - [ ] Backend performance
  - [ ] Frontend performance
  - [ ] Database metrics

### Alarms Configured
- [ ] CPU > 80% alarm
- [ ] Memory > 85% alarm
- [ ] Disk usage > 90% alarm
- [ ] Unhealthy target count > 0 alarm
- [ ] API error rate > 5% alarm
- [ ] ALB response time > 2s alarm
- [ ] Database connection pool alarm
- [ ] Cost threshold alarm

### SNS Notifications
- [ ] SNS topic created
- [ ] Email subscriptions configured
- [ ] Slack integration (optional)
- [ ] PagerDuty integration (optional)

### Log Analysis
- [ ] Log retention configured (e.g., 30 days)
- [ ] Log filters created for errors
- [ ] Insights queries prepared
- [ ] CloudWatch Logs agent running

---

## Testing & Validation

### Functionality Testing
- [ ] Home page loads correctly
- [ ] Add experience form works
- [ ] Can submit new experience
- [ ] Experience details page loads
- [ ] Can view trip details
- [ ] All API endpoints responsive
- [ ] Database operations working
- [ ] CORS not blocking requests

### Performance Testing
- [ ] Backend responds < 500ms
- [ ] Frontend loads in < 3s
- [ ] API handles concurrent requests
- [ ] Load balancer distributing traffic
- [ ] No timeouts with 100 concurrent users

### Security Testing
- [ ] HTTPS enforced (http redirects to https)
- [ ] SSL/TLS certificate valid
- [ ] Security headers present:
  - [ ] Strict-Transport-Security
  - [ ] X-Content-Type-Options
  - [ ] X-Frame-Options
  - [ ] X-XSS-Protection

- [ ] CORS properly configured
- [ ] No sensitive data in logs
- [ ] No exposed credentials
- [ ] Database access restricted

### Disaster Recovery Testing
- [ ] Kill one backend instance - traffic shifts to others
- [ ] Kill one frontend instance - traffic shifts to others
- [ ] Database failover works
- [ ] Backup restoration tested
- [ ] Recovery time documented

---

## Scaling Verification

### Horizontal Scaling
- [ ] Multiple backend instances running
- [ ] Multiple frontend instances running
- [ ] Load balancer distributing traffic evenly
- [ ] Health checks working for all instances
- [ ] Can add/remove instances without downtime

### Auto-Scaling (Optional)
- [ ] Auto-scaling group created (backend)
- [ ] Auto-scaling group created (frontend)
- [ ] Scaling policies configured
- [ ] Scale-up triggers tested
- [ ] Scale-down triggers tested

---

## Documentation Complete
- [ ] Architecture diagram created (draw.io)
- [ ] SETUP_GUIDE.md - Development setup documented
- [ ] DEPLOYMENT_GUIDE.md - Production deployment documented
- [ ] ARCHITECTURE_DIAGRAM_GUIDE.md - Diagram creation guide
- [ ] PROJECT_SUMMARY.md - Project overview
- [ ] This checklist updated with actual values

---

## Post-Deployment

### Monitoring (First Week)
- [ ] Monitor CloudWatch metrics hourly
- [ ] Check logs for errors
- [ ] Monitor response times
- [ ] Track error rates
- [ ] Monitor resource usage
- [ ] Verify backup completion

### Maintenance Tasks
- [ ] Update package dependencies
- [ ] Run security audits
- [ ] Optimize slow queries
- [ ] Review and compress logs
- [ ] Document any issues encountered

### Performance Optimization
- [ ] Enable caching where applicable
- [ ] Optimize database queries
- [ ] Compress static assets
- [ ] Configure CDN
- [ ] Implement pagination for large datasets

### Security Hardening
- [ ] Run security scan
- [ ] Update SSL/TLS settings
- [ ] Review security group rules
- [ ] Enable WAF (Web Application Firewall)
- [ ] Regular penetration testing

---

## Sign-Off

- [ ] All checklist items completed
- [ ] Application tested and verified
- [ ] Monitoring and alerting active
- [ ] Documentation complete
- [ ] Team trained on deployment
- [ ] Runbook created for common issues

**Deployment Completed By:** ___________________  
**Date:** ___________________  
**Environment:** Production  
**Status:** ✅ Ready for Production  

---

## Emergency Contacts

- **DevOps Lead:** _____________________
- **Database Admin:** _____________________
- **Security Officer:** _____________________
- **Emergency Line:** _____________________

---

## Quick Reference

### Critical URLs
- **Application:** https://yourdomain.com
- **API Health:** https://yourdomain.com/api/health
- **AWS Console:** https://console.aws.amazon.com
- **CloudFlare Dashboard:** https://dash.cloudflare.com
- **CloudWatch:** https://console.aws.amazon.com/cloudwatch

### Critical Paths
- **Backend Code:** /home/ubuntu/TravelMemory/backend
- **Frontend Code:** /home/ubuntu/TravelMemory/frontend
- **Nginx Config:** /etc/nginx/sites-available/travelmemory
- **SSL Cert:** /etc/ssl/certs/yourdomain.com.crt
- **Logs:** /var/log/nginx/, CloudWatch Logs

### Emergency Commands
```bash
# Restart backend
pm2 restart backend

# Restart Nginx
sudo systemctl restart nginx

# View backend logs
pm2 logs backend

# View Nginx logs
sudo tail -f /var/log/nginx/error.log

# Check system resources
top

# Check disk space
df -h
```

---

**For detailed instructions, refer to DEPLOYMENT_GUIDE.md**
