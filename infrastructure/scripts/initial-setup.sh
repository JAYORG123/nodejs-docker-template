#!/bin/bash
# ============================================
# INITIAL STAGING SERVER SETUP SCRIPT
# ============================================
# This script performs the initial deployment of the application
# Run this only once when setting up a new staging/production server
#
# Usage: ./initial-setup.sh

set -e  # Exit immediately if a command exits with a non-zero status

# ============================================
# CONFIGURATION
# ============================================
REPO_URL="https://github.com/ktx-jay/docker-demo.git"
BRANCH="main"  # or "staging" for staging environment
APP_DIR="$HOME/app"
COMPOSE_FILE="infrastructure/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# HELPER FUNCTIONS
# ============================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================
# CHECK PREREQUISITES
# ============================================
log_info "Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install Git first."
    exit 1
fi

log_info "All prerequisites met!"

# ============================================
# CLONE REPOSITORY
# ============================================
log_info "Setting up application directory..."

# Check if directory already exists
if [ -d "$APP_DIR" ]; then
    log_warn "Directory $APP_DIR already exists!"
    read -p "Do you want to remove it and start fresh? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing existing directory..."
        rm -rf "$APP_DIR"
    else
        log_error "Cannot proceed with existing directory. Exiting."
        exit 1
    fi
fi

# Clone the repository
log_info "Cloning repository from $REPO_URL..."
git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"

if [ $? -ne 0 ]; then
    log_error "Failed to clone repository. Please check your Git credentials and repository URL."
    exit 1
fi

cd "$APP_DIR"
log_info "Repository cloned successfully!"

# ============================================
# CREATE ENVIRONMENT FILE
# ============================================
log_info "Setting up environment variables..."

# Check if .env already exists
if [ -f .env ]; then
    log_warn ".env file already exists. Backing it up..."
    mv .env .env.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create .env file
cat > .env << 'EOF'
# ============================================
# STAGING/PRODUCTION ENVIRONMENT VARIABLES
# ============================================

# Node Environment
NODE_ENV=production
PORT=3000

# MongoDB Configuration
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=CHANGE_THIS_PASSWORD_NOW
MONGO_INITDB_DATABASE=dockerapp

# MongoDB Connection String (update with your credentials)
MONGO_URI=mongodb://admin:CHANGE_THIS_PASSWORD_NOW@mongodb:27017/dockerapp?authSource=admin

# Add any other environment variables your app needs
EOF

log_warn "IMPORTANT: Please edit the .env file and update the passwords!"
log_warn "File location: $APP_DIR/.env"
echo ""
read -p "Press Enter to open the .env file in nano editor (or Ctrl+C to skip)..."

# Try to open in editor (nano, vim, or vi)
if command -v nano &> /dev/null; then
    nano .env
elif command -v vim &> /dev/null; then
    vim .env
elif command -v vi &> /dev/null; then
    vi .env
else
    log_warn "No text editor found. Please manually edit: $APP_DIR/.env"
fi

# ============================================
# BUILD AND START CONTAINERS
# ============================================
log_info "Building Docker images..."

# Build images
docker compose -f "$COMPOSE_FILE" build

if [ $? -ne 0 ]; then
    log_error "Failed to build Docker images. Check the logs above."
    exit 1
fi

log_info "Starting containers..."

# Start containers in detached mode
docker compose -f "$COMPOSE_FILE" up -d

if [ $? -ne 0 ]; then
    log_error "Failed to start containers. Check the logs above."
    exit 1
fi

# ============================================
# VERIFY DEPLOYMENT
# ============================================
log_info "Waiting for services to start (30 seconds)..."
sleep 30

# Check if containers are running
log_info "Checking container status..."
docker compose -f "$COMPOSE_FILE" ps

# Try to check health endpoint
log_info "Checking application health..."
if command -v curl &> /dev/null; then
    for i in {1..5}; do
        if curl -s http://localhost:3000/health > /dev/null; then
            log_info "✅ Application is healthy!"
            break
        else
            log_warn "Health check attempt $i/5 failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
else
    log_warn "curl not installed. Skipping health check."
fi

# ============================================
# SETUP COMPLETE
# ============================================
echo ""
echo "============================================"
log_info "🎉 Initial setup complete!"
echo "============================================"
echo ""
echo "📁 Application directory: $APP_DIR"
echo "🐳 Containers are running!"
echo ""
echo "📝 Useful commands:"
echo "  - View logs:        cd $APP_DIR && ./logs.sh"
echo "  - Check status:     cd $APP_DIR && ./status.sh"
echo "  - Restart:          cd $APP_DIR && ./restart.sh"
echo "  - Stop:             cd $APP_DIR && ./stop.sh"
echo "  - Deploy updates:   ~/deploy.sh (from outside app folder)"
echo ""
echo "🌐 Access your application:"
echo "  - API: http://localhost:3000"
echo "  - Health: http://localhost:3000/health"
echo ""
echo "⚠️  IMPORTANT: Make sure to:"
echo "  1. Update passwords in .env file"
echo "  2. Set up a reverse proxy (Nginx) for production"
echo "  3. Configure SSL/TLS certificates"
echo "  4. Set up monitoring and backups"
echo ""
