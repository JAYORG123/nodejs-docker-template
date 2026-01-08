# Docker Node.js + MongoDB Task API

A production-ready RESTful API built with **Node.js**, **Express**, **TypeScript**, and **MongoDB**, fully containerized with **Docker**. This project demonstrates best practices for building, deploying, and managing containerized applications with multi-stage Docker builds, health checks, and automated deployment scripts.

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Local Development](#local-development)
  - [Production Deployment](#production-deployment)
- [API Endpoints](#-api-endpoints)
- [Docker Configuration](#-docker-configuration)
- [Deployment Scripts](#-deployment-scripts)
- [Environment Variables](#-environment-variables)
- [Health Checks](#-health-checks)
- [Graceful Shutdown](#-graceful-shutdown)
- [Resource Management](#-resource-management)
- [Security Features](#-security-features)
- [Monitoring & Logging](#-monitoring--logging)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **TypeScript** - Full type safety with strict mode enabled
- **RESTful API** - CRUD operations for task management
- **MongoDB Integration** - Mongoose ODM with proper schema validation
- **Docker Multi-Stage Builds** - Optimized production images (minimal size)
- **Health Checks** - Application and database health monitoring
- **Graceful Shutdown** - Proper signal handling for zero-downtime deployments
- **Resource Limits** - CPU and memory constraints for production stability
- **Security Best Practices** - Non-root user, read-only filesystem where possible
- **Automated Scripts** - Initial setup, deployment, monitoring, and management
- **Production Ready** - Logging, restart policies, and error handling

## 🛠 Tech Stack

| Technology         | Version   | Purpose                       |
| ------------------ | --------- | ----------------------------- |
| **Node.js**        | 20 Alpine | JavaScript runtime            |
| **TypeScript**     | 5.3+      | Type-safe JavaScript          |
| **Express**        | 4.18+     | Web framework                 |
| **MongoDB**        | 7         | NoSQL database                |
| **Mongoose**       | 8.0+      | MongoDB ODM                   |
| **Docker**         | Latest    | Containerization              |
| **Docker Compose** | Latest    | Multi-container orchestration |

## 🏗 Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      Docker Network                       │
│                  (nodejs-mongodb-network-prod)            │
│                                                           │
│  ┌─────────────────────┐      ┌────────────────────┐    │
│  │   Node.js App       │      │     MongoDB        │    │
│  │   (Port 3000)       │─────▶│   (Port 27017)     │    │
│  │   - Express API     │      │   - Persistent     │    │
│  │   - Health Checks   │      │     Storage        │    │
│  │   - Resource Limits │      │   - Authentication │    │
│  └─────────────────────┘      └────────────────────┘    │
│                                                           │
└──────────────────────────────────────────────────────────┘
           │
           ▼
    Host Port 3000 ──▶ Container Port 3000
```

## 📁 Project Structure

```
Docker/
├── src/
│   └── server.ts                 # Main application server with API routes
├── infrastructure/
│   ├── docker-compose.yml        # Production Docker Compose configuration
│   ├── Dockerfile                # Multi-stage production Dockerfile
│   └── scripts/
│       ├── deploy.sh            # Continuous deployment script
│       ├── initial-setup.sh     # First-time server setup
│       ├── restart.sh           # Restart containers
│       ├── status.sh            # Check container and app status
│       └── stop.sh              # Stop all containers
├── package.json                  # Node.js dependencies and scripts
├── tsconfig.json                 # TypeScript configuration
└── README.md                     # This file
```

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (for cloning and version control)
- **Node.js** (version 20 or higher) - only for local development
- **npm** (version 9 or higher) - only for local development

### Verify Installation

```bash
docker --version
docker compose version
git --version
node --version  # Optional for local dev
npm --version   # Optional for local dev
```

## 🚀 Getting Started

### Local Development

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd Docker
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Create environment file**

   ```bash
   # Create .env file in the root directory
   echo "MONGO_URI=mongodb://localhost:27017/dockerapp" > .env
   echo "PORT=3000" >> .env
   ```

4. **Run MongoDB locally** (optional if not using Docker)

   ```bash
   docker run -d -p 27017:27017 --name mongodb mongo:7
   ```

5. **Start development server**

   ```bash
   npm run start:dev
   ```

6. **Access the API**
   - API: http://localhost:3000
   - Health Check: http://localhost:3000/health

### Production Deployment

#### Option 1: Using Docker Compose (Recommended)

1. **Navigate to infrastructure directory**

   ```bash
   cd infrastructure
   ```

2. **Create environment file for production**

   ```bash
   cat > .env << EOF
   MONGO_ROOT_USERNAME=admin
   MONGO_ROOT_PASSWORD=your_secure_password_here
   EOF
   ```

3. **Build and start containers**

   ```bash
   docker compose up -d
   ```

4. **Verify deployment**
   ```bash
   docker compose ps
   curl http://localhost:3000/health
   ```

#### Option 2: Using Automated Scripts

1. **Initial Setup** (first time only)

   ```bash
   cd infrastructure/scripts
   chmod +x *.sh
   ./initial-setup.sh
   ```

2. **Deploy Updates**

   ```bash
   ./deploy.sh
   ```

3. **Check Status**

   ```bash
   ./status.sh
   ```

4. **Stop Services**

   ```bash
   ./stop.sh
   ```

5. **Restart Services**
   ```bash
   ./restart.sh
   ```

## 🐳 Docker Configuration

### Multi-Stage Build Process

The Dockerfile uses a **3-stage build** for optimal production images:

1. **Builder Stage** - Compiles TypeScript to JavaScript
2. **Dependencies Stage** - Installs only production dependencies
3. **Production Stage** - Creates minimal runtime image

**Benefits:**

- **Smaller Image Size**: Only compiled JS and production dependencies
- **Faster Deployments**: Reduced image transfer time
- **Enhanced Security**: No development tools in production
- **Layer Caching**: Efficient rebuilds

### Key Docker Features

- **Alpine Linux Base**: Minimal attack surface
- **Non-Root User**: Security best practice (user: nodejs, uid: 1001)
- **dumb-init**: Proper signal handling for graceful shutdowns
- **Health Checks**: Automatic container health monitoring
- **Resource Limits**:
  - CPU: 0.5-1.0 cores
  - Memory: 256MB-512MB (app), 512MB-1GB (mongodb)

### Docker Commands

```bash
# Build image
docker compose build

# Start containers (detached)
docker compose up -d

# View logs
docker compose logs -f app

# Stop containers
docker compose down

# Remove volumes
docker compose down -v

# Rebuild without cache
docker compose build --no-cache

# View resource usage
docker stats
```

## 📜 Deployment Scripts

### `initial-setup.sh`

First-time server setup script. Clones repository, configures environment, and starts services.

```bash
./initial-setup.sh
```

**What it does:**

- Checks prerequisites (Docker, Git)
- Clones repository
- Creates `.env` file with prompts
- Builds Docker images
- Starts containers
- Validates deployment

### `deploy.sh`

Continuous deployment script for pushing updates.

```bash
./deploy.sh
```

**What it does:**

- Pulls latest code from Git
- Creates backup of current deployment
- Rebuilds Docker images
- Performs zero-downtime deployment
- Runs health checks
- Rollback on failure

### `status.sh`

Checks container status and application health.

```bash
./status.sh
```

**Output:**

- Container status (running/stopped)
- Health check results
- Resource usage
- Database connectivity

### `restart.sh`

Restarts all containers without rebuilding.

```bash
./restart.sh
```

### `stop.sh`

Gracefully stops all containers.

```bash
./stop.sh
```

## 🔐 Environment Variables

### Application Variables

Create a `.env` file in the root directory:

```env
# Application
PORT=3000
NODE_ENV=production

# Database
MONGO_URI=mongodb://admin:password@mongodb:27017/dockerapp?authSource=admin

# MongoDB Credentials
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=your_secure_password_here
```

### Security Notes

⚠️ **Important:**

- Never commit `.env` files to Git
- Use strong passwords for production
- Consider using Docker secrets or Kubernetes secrets for sensitive data
- Rotate credentials regularly

## 💓 Health Checks

### Application Health Check

**Endpoint:** `GET /health`

**Response:**

```json
{
  "status": "OK",
  "timestamp": "2026-01-08T12:00:00.000Z",
  "database": "Connected"
}
```

### Container Health Checks

**Node.js App:**

- **Check:** `wget http://localhost:3000/health`
- **Interval:** 30 seconds
- **Timeout:** 10 seconds
- **Retries:** 3
- **Start Period:** 40 seconds

**MongoDB:**

- **Check:** `mongosh ping command`
- **Interval:** 30 seconds
- **Timeout:** 10 seconds
- **Retries:** 5
- **Start Period:** 60 seconds

### Monitor Health Status

```bash
# Check health via Docker
docker compose ps

# Check health via API
curl http://localhost:3000/health

# View logs
docker compose logs -f app
```

## 📊 Resource Management

### Resource Limits

**Application Container:**

- **CPU Limit:** 1.0 core (maximum)
- **CPU Reservation:** 0.5 cores (guaranteed)
- **Memory Limit:** 512MB (maximum)
- **Memory Reservation:** 256MB (guaranteed)

**MongoDB Container:**

- **CPU Limit:** 1.0 core (maximum)
- **CPU Reservation:** 0.5 cores (guaranteed)
- **Memory Limit:** 1GB (maximum)
- **Memory Reservation:** 512MB (guaranteed)

### Monitor Resource Usage

```bash
# Real-time stats
docker stats

# Container-specific stats
docker stats nodejs-app-prod mongodb-prod
```

## 🔒 Security Features

### Application Security

✅ **Implemented:**

- Non-root user execution
- No development dependencies in production
- Read-only root filesystem where possible
- Health checks for automatic restart
- Graceful shutdown handling

## 🔄 Graceful Shutdown

The application implements **complete graceful shutdown** to ensure clean exits and prevent data corruption when containers are stopped or restarted.

### How It Works

When a termination signal is received (e.g., `docker compose down`):

1. **Signal Reception** - `dumb-init` (PID 1) forwards SIGTERM/SIGINT to the Node.js process
2. **Stop New Connections** - HTTP server stops accepting new requests
3. **Complete Active Requests** - Existing requests are allowed to finish processing
4. **Close Database** - MongoDB connections are closed properly
5. **Clean Exit** - Application exits with code 0 (success)

### Benefits

✅ **No Request Interruption** - Active requests complete before shutdown  
✅ **No Data Loss** - Database operations finish and connections close cleanly  
✅ **No Connection Leaks** - All resources (file handles, sockets) are released  
✅ **Faster Restarts** - Proper cleanup enables quicker container restarts

### Implementation Components

**1. dumb-init (Docker Layer)**

- Acts as PID 1 inside the container
- Properly forwards termination signals to Node.js
- Prevents zombie processes

**2. Signal Handlers (Application Layer)**

```typescript
process.on("SIGTERM", gracefulShutdown);
process.on("SIGINT", gracefulShutdown);
```

**3. Safety Timeout**

- 30-second timeout prevents hanging shutdowns
- Forces exit if graceful shutdown takes too long

### Verify Graceful Shutdown

Test the shutdown behavior:

```bash
# Start the container
docker compose up

# In another terminal, stop it and watch logs
docker compose down
```

**Expected Output:**

```
👋 SIGTERM signal received: starting graceful shutdown
🛑 HTTP server closed (no longer accepting connections)
📦 MongoDB connection closed
✅ Graceful shutdown completed
```

- Input validation on API endpoints

### Network Security

✅ **Implemented:**

- Isolated Docker network
- MongoDB not exposed to host (commented out in production)
- Internal communication only

### Recommendations

🔐 **Additional Steps:**

1. Enable TLS/SSL for MongoDB connections
2. Use Docker secrets for credentials
3. Implement rate limiting
4. Add authentication/authorization (JWT)
5. Set up a reverse proxy (Nginx) with HTTPS
6. Regular security updates and scanning

## 📝 Monitoring & Logging

### Log Management

**Log Configuration:**

- **Driver:** json-file
- **Max Size:** 10MB per file
- **Max Files:** 3 (30MB total)

**View Logs:**

```bash
# All containers
docker compose logs -f

# Specific container
docker compose logs -f app
docker compose logs -f mongodb

# Last 100 lines
docker compose logs --tail=100 app
```

### Production Monitoring

**Recommended Tools:**

- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **Loki** - Log aggregation
- **cAdvisor** - Container metrics
- **Node Exporter** - System metrics

## 🔧 Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error:** `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Solution:**

```bash
# Find process using port 3000
netstat -ano | findstr :3000  # Windows
lsof -i :3000                 # Linux/Mac

# Stop the process or change port in .env
PORT=3001
```

#### 2. MongoDB Connection Failed

**Error:** `MongooseServerSelectionError: connect ECONNREFUSED`

**Solution:**

```bash
# Check if MongoDB is running
docker compose ps

# Check MongoDB logs
docker compose logs mongodb

# Restart MongoDB
docker compose restart mongodb
```

#### 3. Container Unhealthy

**Error:** Container status shows "unhealthy"

**Solution:**

```bash
# Check health logs
docker inspect nodejs-app-prod | grep -A 10 Health

# Check application logs
docker compose logs app

# Restart with fresh build
docker compose down
docker compose up -d --build
```

#### 4. Out of Memory

**Error:** Container crashes with exit code 137

**Solution:**

```bash
# Increase memory limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 1G  # Increase from 512M
```

#### 5. Build Failures

**Error:** `failed to solve: process "/bin/sh -c npm ci" did not complete successfully`

**Solution:**

```bash
# Clear Docker cache
docker compose build --no-cache

# Check package.json for errors
npm install  # Test locally first
```

### Debug Mode

Run containers in foreground with full logs:

```bash
docker compose up
```

### Reset Everything

Complete clean start:

```bash
# Stop and remove everything
docker compose down -v

# Remove all related images
docker rmi nodejs-app-prod:latest mongo:7

# Remove network
docker network rm nodejs-mongodb-network-prod

# Start fresh
docker compose up -d --build
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines

- Follow TypeScript best practices
- Maintain test coverage
- Update documentation
- Follow conventional commits
- Ensure all tests pass

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)

## 🙋 Support

For issues and questions:

- Create an issue on GitHub
- Check existing issues and discussions
- Review the troubleshooting section

---

**Built with ❤️ using Docker, Node.js, and TypeScript**
