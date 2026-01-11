# TravelMemory - Quick Start & Setup Guide

## Development Environment Setup

### Prerequisites
- Node.js v16+ and npm
- MongoDB (local or MongoDB Atlas account)
- Git
- VS Code or any code editor

---

## Step-by-Step Setup

### 1. Clone the Repository
```bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory
```

### 2. Backend Setup

#### Navigate to Backend Directory
```bash
cd backend
```

#### Install Dependencies
```bash
npm install
```

#### Configure Environment Variables
Create/Update `.env` file in the `backend` directory:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
MONGO_URI=mongodb+srv://your_username:your_password@your_cluster.mongodb.net/travel_memory?retryWrites=true&w=majority

# CORS Configuration
FRONTEND_URL=http://localhost:3000

# JWT Secret
JWT_SECRET=your_development_secret_key

# Logging
LOG_LEVEL=debug
```

#### Start Backend Server
```bash
npm start
```

The backend will run on `http://localhost:3000`

#### Verify Backend is Running
```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{ "ok": true, "env": "development" }
```

---

### 3. Frontend Setup

#### Navigate to Frontend Directory (from project root)
```bash
cd frontend
```

#### Install Dependencies
```bash
npm install
```

#### Configure Environment Variables
Create/Update `.env` file in the `frontend` directory:

```env
# Backend Connection
REACT_APP_BACKEND_URL=http://localhost:3000

# Environment
REACT_APP_ENV=development
```

#### Start Frontend Development Server
```bash
npm start
```

The frontend will open at `http://localhost:3000` (or port 3001 if 3000 is busy)

---

## API Endpoints

### Health Check
```
GET /api/health
```
Response: `{ "ok": true, "env": "development" }`

### Get All Trips
```
GET /api/trips
```

### Get Trip by ID
```
GET /trip/:id
```

### Create New Trip
```
POST /trip
Content-Type: application/json

{
  "name": "Trip Name",
  "description": "Trip Description",
  "startDate": "2024-01-15",
  "endDate": "2024-01-20",
  "location": "Location Name"
}
```

### Update Trip
```
PUT /trip/:id
Content-Type: application/json

{
  "name": "Updated Name",
  "description": "Updated Description"
}
```

### Delete Trip
```
DELETE /trip/:id
```

---

## Environment Variables Reference

### Backend (.env)

| Variable | Purpose | Example |
|----------|---------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment type | `development` or `production` |
| `MONGO_URI` | MongoDB connection string | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `FRONTEND_URL` | Frontend URL for CORS | `http://localhost:3000` |
| `JWT_SECRET` | Secret key for JWT tokens | `your_secret_key_here` |
| `LOG_LEVEL` | Logging level | `debug`, `info`, `warn`, `error` |

### Frontend (.env)

| Variable | Purpose | Example |
|----------|---------|---------|
| `REACT_APP_BACKEND_URL` | Backend API URL | `http://localhost:3000` |
| `REACT_APP_ENV` | Environment | `development` or `production` |

---

## Project Structure

```
TravelMemory/
├── backend/
│   ├── controllers/
│   │   └── trip.controller.js
│   ├── models/
│   │   └── trip.model.js
│   ├── routes/
│   │   └── trip.routes.js
│   ├── conn.js           # Database connection
│   ├── index.js          # Main server file
│   ├── package.json
│   └── .env              # Environment configuration
│
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── pages/
│   │   │   │   ├── AddExperience.js
│   │   │   │   ├── ExperienceDetails.js
│   │   │   │   └── Home.js
│   │   │   └── UIC/
│   │   │       ├── Card.js
│   │   │       ├── FeaturedCard.js
│   │   │       └── Header.js
│   │   ├── App.js
│   │   ├── url.js        # API URL configuration
│   │   └── index.js
│   ├── package.json
│   └── .env              # Frontend configuration
│
├── nginx.conf            # Nginx reverse proxy config
├── DEPLOYMENT_GUIDE.md   # Production deployment guide
└── README.md
```

---

## Common Development Tasks

### Install New Package
```bash
# Backend
cd backend && npm install <package-name>

# Frontend
cd frontend && npm install <package-name>
```

### Check for Vulnerabilities
```bash
npm audit
```

### Fix Vulnerabilities
```bash
npm audit fix
```

### Run Tests
```bash
npm test
```

### Build for Production
```bash
# Backend
npm run build  # If configured

# Frontend
npm run build
```

---

## Debugging

### Backend Debugging
```bash
# Enable debug logging
DEBUG=* npm start

# Or use Node debugger
node --inspect index.js
```

### Frontend Debugging
1. Open browser DevTools (F12)
2. Use React Developer Tools extension
3. Check Network tab for API calls
4. Check Console for errors

### Check Logs
```bash
# Backend logs
tail -f /var/log/pm2/travelmemory-backend-out.log

# Frontend logs
Check browser console
```

---

## Database Setup

### Using MongoDB Atlas (Cloud)

1. Create account at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a cluster
3. Create database user with strong password
4. Whitelist IP addresses
5. Get connection string
6. Add to `.env`:
```env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/travel_memory?retryWrites=true&w=majority
```

### Using Local MongoDB

1. Install MongoDB Community Edition
2. Start MongoDB service:
```bash
# Windows
mongod

# Linux/Mac
brew services start mongodb-community
```

3. Connection string:
```env
MONGO_URI=mongodb://localhost:27017/travel_memory
```

---

## Deployment

For production deployment instructions, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

Quick steps:
1. Update `.env` files with production values
2. Build React app: `npm run build`
3. Use PM2 to manage backend process
4. Configure Nginx reverse proxy
5. Set up SSL certificate
6. Configure domain/DNS

---

## Troubleshooting

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000  # Linux/Mac
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>  # Linux/Mac
taskkill /PID <PID> /F  # Windows
```

### CORS Errors
- Check `FRONTEND_URL` in backend `.env`
- Verify it matches the frontend URL exactly
- Restart backend server

### Can't Connect to Database
- Verify connection string
- Check IP whitelist (MongoDB Atlas)
- Verify credentials
- Test connection with MongoDB Compass

### Frontend Can't Reach Backend
- Check `REACT_APP_BACKEND_URL` in frontend `.env`
- Verify backend is running
- Check network tab in DevTools
- Verify CORS configuration

---

## Performance Tips

### Backend
- Use connection pooling
- Implement caching with Redis
- Optimize database queries
- Use async/await properly
- Implement pagination for APIs

### Frontend
- Use React.lazy() for code splitting
- Implement image optimization
- Use production builds
- Enable gzip compression
- Implement service workers for caching

---

## Security Best Practices

1. **Environment Variables**: Never commit `.env` files
2. **Dependencies**: Regularly update with `npm audit fix`
3. **Passwords**: Use strong, unique passwords
4. **CORS**: Limit to trusted origins only
5. **Authentication**: Implement JWT properly
6. **HTTPS**: Always use HTTPS in production
7. **Input Validation**: Validate all user inputs
8. **Error Messages**: Don't expose sensitive info in errors

---

## Getting Help

- Check GitHub Issues
- Review error logs
- Consult DEPLOYMENT_GUIDE.md
- Ask in project discussions

---

## Next Steps

1. ✅ Clone the repository
2. ✅ Set up backend with MongoDB
3. ✅ Configure environment variables
4. ✅ Start both frontend and backend
5. ✅ Test API endpoints
6. ✅ Build frontend for production
7. ✅ Deploy to AWS/Production (see DEPLOYMENT_GUIDE.md)

Happy coding! 🚀
