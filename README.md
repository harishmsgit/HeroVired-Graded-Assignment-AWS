<<<<<<< Updated upstream
<<<<<<< HEAD
# TravelMemory
=======
# Travel Memory
=======
# Travel Memory Application
>>>>>>> Stashed changes

A full-stack web application for sharing and managing travel experiences with a React frontend and Node.js/Express backend.

## 📋 Quick Start

### For Development
1. See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for complete development environment setup

### For Production Deployment
1. See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for step-by-step production deployment
2. See [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) for verification checklist
3. See [ARCHITECTURE_DIAGRAM_GUIDE.md](./ARCHITECTURE_DIAGRAM_GUIDE.md) for system architecture

## 🏗️ Project Structure

```
TravelMemory/
├── backend/                    # Node.js/Express API
│   ├── controllers/            # Route controllers
│   ├── models/                 # Database models
│   ├── routes/                 # API routes
│   ├── index.js               # Main server file
│   ├── conn.js                # Database connection
│   ├── package.json
│   └── .env                   # Backend configuration
│
├── frontend/                   # React application
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/            # Page components
│   │   ├── App.js            # Main component
│   │   ├── url.js            # API configuration
│   │   └── index.js
│   ├── public/               # Static assets
│   ├── package.json
│   └── .env                  # Frontend configuration
│
├── nginx.conf                # Nginx reverse proxy configuration
├── SETUP_GUIDE.md           # Development setup guide
├── DEPLOYMENT_GUIDE.md      # Production deployment guide
├── DEPLOYMENT_CHECKLIST.md  # Deployment verification
├── ARCHITECTURE_DIAGRAM_GUIDE.md  # Architecture documentation
└── PROJECT_SUMMARY.md       # Project overview
```

## 🔧 Configuration

### Backend (.env)
```env
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/travel_memory
FRONTEND_URL=http://localhost:3000
JWT_SECRET=your_secret_key
LOG_LEVEL=debug
```

### Frontend (.env)
```env
REACT_APP_BACKEND_URL=http://localhost:3000
REACT_APP_ENV=development
```

## 📊 Data Format

Example trip data structure:
```json
{
    "tripName": "Incredible India",
    "startDateOfJourney": "19-03-2022",
    "endDateOfJourney": "27-03-2022",
    "nameOfHotels": "Hotel Namaste, Backpackers Club",
    "placesVisited": "Delhi, Kolkata, Chennai, Mumbai",
    "totalCost": 800000,
    "tripType": "leisure",
    "experience": "Amazing journey with wonderful memories...",
    "image": "https://example.com/image.jpg",
    "shortDescription": "India is a wonderful country with rich culture and good people.",
    "featured": true
}
```
<<<<<<< HEAD
>>>>>>> a860ae5 (Update README.md)
=======

## 🚀 Deployment Architecture

<<<<<<< Updated upstream
For frontend, you need to create `.env` file and put the following content (remember to change it based on your requirements):
```bash
REACT_APP_BACKEND_URL=http://localhost:3001
```
>>>>>>> 722b4ee (UPDATE: updating the readme)
=======
- **Frontend**: React app served through Nginx reverse proxy
- **Backend**: Node.js/Express API with MongoDB
- **Load Balancer**: AWS ALB for distributing traffic
- **Domain**: Cloudflare DNS with HTTPS
- **Scaling**: Multiple instances with auto-scaling

See [ARCHITECTURE_DIAGRAM_GUIDE.md](./ARCHITECTURE_DIAGRAM_GUIDE.md) for detailed architecture diagrams.

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Local development setup and quick start |
| [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) | Complete production deployment guide |
| [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) | Step-by-step deployment verification |
| [ARCHITECTURE_DIAGRAM_GUIDE.md](./ARCHITECTURE_DIAGRAM_GUIDE.md) | System architecture and diagram creation |
| [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) | Project overview and completion status |

## 🔑 Key Features

✅ Multi-instance backend deployment  
✅ Load balancing with AWS ALB  
✅ Nginx reverse proxy with SSL/TLS  
✅ Cloudflare DNS integration  
✅ MongoDB database with replica sets  
✅ Health check endpoints  
✅ CORS security configuration  
✅ Environment-based configuration  
✅ PM2 process management  
✅ Comprehensive monitoring setup  

## 🛡️ Security

- HTTPS/SSL encryption enforced
- CORS validation against origin
- JWT authentication ready
- Security headers configured (HSTS, X-Frame-Options, etc.)
- Database access restricted to backend only
- Environment variables for sensitive data
- Rate limiting support

## 📈 Scaling

The application supports:
- Horizontal scaling with multiple backend instances
- Frontend load balancing across multiple instances
- Database replica sets for high availability
- Auto-scaling policies (when configured)
- CDN integration for static assets

## 🔍 Monitoring

CloudWatch integration includes:
- Application logs aggregation
- Performance metrics
- Error tracking
- Resource utilization monitoring
- Automated alerting via SNS/Email

## 🆘 Troubleshooting

For common issues and solutions, refer to:
- [SETUP_GUIDE.md - Troubleshooting Section](./SETUP_GUIDE.md#troubleshooting)
- [DEPLOYMENT_GUIDE.md - Troubleshooting Section](./DEPLOYMENT_GUIDE.md#troubleshooting)
- CloudWatch Logs in AWS Console

## 📞 Support

- **Development Issues**: See SETUP_GUIDE.md
- **Production Issues**: See DEPLOYMENT_GUIDE.md
- **Architecture Questions**: See ARCHITECTURE_DIAGRAM_GUIDE.md
- **Deployment Help**: See DEPLOYMENT_CHECKLIST.md

## 👥 Author

- **Original Developer**: Prashant Dey
- **Repository**: [GitHub - UnpredictablePrashant/TravelMemory](https://github.com/UnpredictablePrashant/TravelMemory)

## 📄 License

See [LICENSE](./LICENSE) file for details.

## 🎯 Next Steps

1. **Development**: Follow [SETUP_GUIDE.md](./SETUP_GUIDE.md)
2. **Production**: Follow [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
3. **Verify**: Use [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
4. **Monitor**: Set up CloudWatch per [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#monitoring)

---

**Happy Coding! 🚀**
>>>>>>> Stashed changes
