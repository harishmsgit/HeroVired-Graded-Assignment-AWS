# TravelMemory Application - Architecture Diagram Guide

## Deployment Architecture Diagram (for draw.io)

This guide provides instructions for creating an architecture diagram using draw.io that visualizes the complete TravelMemory deployment.

### Steps to Create the Diagram

1. Go to [draw.io](https://www.draw.io/)
2. Create a new blank diagram
3. Follow the structure below to add components

---

## Architecture Components

### Layer 1: Client & CDN
```
┌─────────────────────────────┐
│    Users/Internet Traffic   │
│    (Multiple Regions)       │
└──────────────┬──────────────┘
               │
       ┌───────▼────────┐
       │ Cloudflare CDN │
       │  (DNS & SSL)   │
       └───────┬────────┘
               │
```

### Layer 2: DNS & Routing
```
       ┌──────────────────┐
       │  AWS Route 53    │
       │  (DNS Service)   │
       └────────┬─────────┘
                │
    ┌───────────┼───────────┐
    │                       │
┌───▼──────┐         ┌──────▼───┐
│ A Record │         │ CNAME     │
│ (Frontend│         │ (API)     │
│ IP)      │         │           │
└──────────┘         └───────────┘
```

### Layer 3: Load Balancing
```
┌────────────────────────────────┐
│   Elastic Load Balancer (ALB)  │
│   - HTTP to HTTPS redirect     │
│   - Route /api/* to backend    │
│   - Route /* to frontend       │
│   - Health checks every 30s    │
└──────────────┬─────────────────┘
               │
       ┌───────┴───────┐
       │               │
```

### Layer 4: Application Servers
```
EC2 Instances (Frontend)          EC2 Instances (Backend)
┌──────────────────────┐         ┌──────────────────────┐
│   Frontend Instance  │         │  Backend Instance 1  │
│   ┌────────────────┐ │         │  ┌────────────────┐  │
│   │ React App      │ │         │  │ Node.js API    │  │
│   │ Port: 8080     │ │         │  │ Port: 3000     │  │
│   └────────────────┘ │         │  └────────────────┘  │
│   ┌────────────────┐ │         │  ┌────────────────┐  │
│   │ Nginx Proxy    │ │         │  │ Express.js     │  │
│   │ Port: 443      │ │         │  │ Controllers    │  │
│   └────────────────┘ │         │  └────────────────┘  │
└──────────────────────┘         └──────────────────────┘
         │                                    │
         │                        ┌───────────┼──────────┐
         │                        │           │          │
         │                   ┌────▼────┐ ┌───▼────┐ ┌──▼──────┐
         │                   │Instance │ │Instance│ │Instance │
         │                   │   2     │ │   3    │ │   4     │
         │                   │Port3001 │ │Port3002│ │Port3003 │
         │                   └─────────┘ └────────┘ └─────────┘
         │
         └─────────────────────────┐
                                   │
```

### Layer 5: Database
```
┌─────────────────────────────────────┐
│     Database Layer                  │
├─────────────────────────────────────┤
│  Primary: MongoDB Replica Set       │
│  - Primary Node (Read/Write)        │
│  - Secondary Node (Read-only)       │
│  - Arbiter Node (Voting)            │
│                                     │
│  Backup: Daily automated snapshots  │
│  Location: AWS S3 / MongoDB Atlas   │
└─────────────────────────────────────┘
```

### Layer 6: Monitoring & Logging
```
┌─────────────────────────────────────┐
│   CloudWatch                        │
│   - Logs aggregation                │
│   - Metrics & Alarms                │
│   - Performance monitoring          │
└─────────────────────────────────────┘
         │
         ├──────────────┬──────────────┐
         │              │              │
      ┌──▼──┐       ┌───▼──┐      ┌──▼────┐
      │Email│       │SNS   │      │Slack  │
      │Alert│       │Topic │      │ Alert │
      └─────┘       └──────┘      └───────┘
```

---

## Draw.io Instructions

### Create the Diagram Step-by-Step:

#### 1. Start with Basic Shapes
- Use **Rectangles** for servers, containers, and services
- Use **Cylinders** for databases
- Use **Diamonds** for decision points
- Use **Circles** for external services

#### 2. Add Color Coding
- **Blue**: AWS Services
- **Green**: Application Servers
- **Orange**: User/Internet Layer
- **Red**: Database/Storage
- **Yellow**: Monitoring/Logging

#### 3. Connect Components
- Use **Arrows** to show data flow
- Add **Labels** to arrows explaining connections
- Use **Dashed Lines** for optional/fallback connections

#### 4. Add Annotations
- Include port numbers
- Show protocols (HTTP, HTTPS, TCP, UDP)
- Add security group names
- Include availability zones

#### 5. Zoom Levels
Create multiple diagrams:
- **High-level**: Overall system architecture
- **Mid-level**: Service interactions
- **Detailed**: Individual component internals

---

## Data Flow in the Architecture

### Request Flow (User to Backend)

```
1. User enters yourdomain.com
   ↓
2. Cloudflare resolves DNS
   ↓
3. Route 53 returns Load Balancer IP
   ↓
4. ALB receives HTTPS request on port 443
   ↓
5. ALB SSL/TLS termination
   ↓
6. ALB routes based on path:
   - /api/* → Backend target group (port 3000)
   - /* → Frontend target group (port 8080)
   ↓
7. Nginx reverse proxy on instance
   ↓
8. Backend/Frontend processes request
   ↓
9. Response sent back through load balancer
   ↓
10. Cloudflare caches if applicable
   ↓
11. User receives response
```

### Database Query Flow

```
Application Server
   ↓
Connection Pool
   ↓
MongoDB Replica Set
   ↓
Primary Node (Write)
   ↓
Secondary Nodes (Read Replicas)
   ↓
Response to Application
```

---

## Scalability Features

### Horizontal Scaling
```
Current State:          Scaled State:
┌──────────┐           ┌──────────┐ ┌──────────┐ ┌──────────┐
│Backend 1 │           │Backend 1 │ │Backend 2 │ │Backend 3 │
└──────────┘    →      └──────────┘ └──────────┘ └──────────┘
     ↑                        ↑
     │                        │
┌─────────┐    →      ┌──────────────┐
│ Load    │           │Load Balancer │
│Balancer │           │(Distribution)│
└─────────┘           └──────────────┘
```

### Database Replication
```
                Primary Node
                    (W/R)
                      │
        ┌─────────────┴─────────────┐
        │                           │
    Secondary 1              Secondary 2
    (Read-only)              (Read-only)
```

---

## Security Architecture

### Network Segmentation
```
┌────────────────────────────────────────────────┐
│             AWS VPC                            │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────────────────────────────────────┐  │
│  │  Public Subnet (Frontend)                │  │
│  │  Security Group: Allow 80, 443 from All │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │ EC2 Frontend Instances             │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│           │                                     │
│  ┌────────▼──────────────────────────────────┐ │
│  │  Private Subnet (Backend)                 │ │
│  │  Security Group: Allow 3000 from ALB only│ │
│  │  ┌────────────────────────────────────┐  │ │
│  │  │ EC2 Backend Instances              │  │ │
│  │  └────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────┘ │
│           │                                     │
│  ┌────────▼──────────────────────────────────┐ │
│  │  Private Subnet (Database)                │ │
│  │  Security Group: Allow 27017 from backend│ │
│  │  ┌────────────────────────────────────┐  │ │
│  │  │ MongoDB Replica Set                │  │ │
│  │  └────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────┘ │
│                                                │
└────────────────────────────────────────────────┘
```

---

## Disaster Recovery Architecture

```
Primary Region:                  Backup Region:
┌────────────────────┐          ┌────────────────────┐
│ Production Cluster │          │  Standby Cluster   │
│ - Frontend (2x)    │          │ - Frontend (2x)    │
│ - Backend (3x)     │   Sync   │ - Backend (3x)     │
│ - Primary DB       │◄────────►│ - Replica DB       │
└────────────────────┘          └────────────────────┘
         │                              │
         ▼                              ▼
    S3 Backup                    S3 Backup
  (every 6 hours)              (every 6 hours)
```

---

## Performance Considerations

### Caching Strategy
```
Request
  │
  ▼
┌─────────────────┐
│ CloudFlare CDN  │
│ (Static Assets) │
└────────┬────────┘
         │
         │ (Cache Miss)
         ▼
┌─────────────────┐
│  Nginx Cache    │
│ (API Responses) │
└────────┬────────┘
         │
         │ (Cache Miss)
         ▼
┌─────────────────┐
│   Application   │
│  (DB Query)     │
└─────────────────┘
```

---

## Monitoring & Observability Stack

```
Applications
     │
     ▼
CloudWatch Logs
     │
     ▼
CloudWatch Metrics
     │
     ├──────────┬─────────────┐
     │          │             │
     ▼          ▼             ▼
  Dashboard  Alarms      Log Insights
     │          │             │
     ├──────────┼─────────────┤
     │          │             │
     ▼          ▼             ▼
  SNS Topic (Notifications)
     │
     ├──────────┬─────────────┐
     │          │             │
     ▼          ▼             ▼
   Email      Slack         PagerDuty
```

---

## Export Instructions

1. After creating diagram in draw.io:
   - Click **File** → **Export**
   - Choose format: PNG (for documentation) or SVG (for scalability)
   - Include in project documentation

2. Alternative: Keep live diagram
   - Share draw.io link in team
   - Update as architecture evolves

---

## Next Steps

1. Create diagram in draw.io following these specifications
2. Export and include in documentation
3. Share with team for review
4. Update diagram when architecture changes

For detailed deployment instructions, refer to **DEPLOYMENT_GUIDE.md**
