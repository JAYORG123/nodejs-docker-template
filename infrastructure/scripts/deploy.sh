#!/bin/bash
# ============================================
# CONTINUOUS DEPLOYMENT SCRIPT
# ============================================
# This script pulls the latest code from Git and redeploys the application
# Run this whenever you want to deploy new changes to staging/production
#
# Usage: ./deploy.sh

set -e  # Exit immediately if a command exits with a non-zero status

# ============================================
# CONFIGURATION
# ============================================
APP_DIR="$HOME/app"  # Application directory
BRANCH="main"  # or "staging" for staging environment
COMPOSE_FILE="infrastructure/docker-compose.yml"
BACKUP_DIR="$HOME/backups"
BACKUP_RETENTION_DAYS=7  # Keep backups for 7 days

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# ============================================
# NAVIGATE TO APP DIRECTORY
# ============================================
log_info "Navigating to application directory: $APP_DIR"

if [ ! -d "$APP_DIR" ]; then
    log_error "Application directory not found: $APP_DIR"
    log_error "Please update APP_DIR in the script configuration."
    exit 1
fi

cd "$APP_DIR" || {
    log_error "Failed to navigate to $APP_DIR"
    exit 1
}

# ============================================
# PRE-DEPLOYMENT CHECKS
# ============================================
log_step "Starting deployment process..."

# Verify we're in the project root
if [ ! -d "infrastructure" ]; then
    log_error "Infrastructure directory not found. Invalid project directory."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "docker-compose file not found at $COMPOSE_FILE"
    exit 1
fi

if [ ! -f .env ]; then
    log_error ".env file not found. Please create it first."
    exit 1
fi

# ============================================
# CREATE BACKUP
# ============================================
log_step "Creating backup before deployment..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP="$BACKUP_DIR/backup_$BACKUP_TIMESTAMP"

# Get current git commit hash for backup naming
CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

log_info "Backing up current deployment..."
mkdir -p "$CURRENT_BACKUP"

# Backup database (MongoDB)
log_info "Backing up MongoDB database..."
docker compose -f "$COMPOSE_FILE" exec -T mongodb mongodump --out=/tmp/backup 2>/dev/null || log_warn "Database backup failed (container might not be running)"
docker compose -f "$COMPOSE_FILE" cp mongodb:/tmp/backup "$CURRENT_BACKUP/mongodb_backup" 2>/dev/null || true

# Backup .env file
cp .env "$CURRENT_BACKUP/.env"

# Save current commit info
echo "Commit: $CURRENT_COMMIT" > "$CURRENT_BACKUP/deployment_info.txt"
echo "Date: $(date)" >> "$CURRENT_BACKUP/deployment_info.txt"

log_info "Backup created at: $CURRENT_BACKUP"

# Clean up old backups (older than BACKUP_RETENTION_DAYS)
log_info "Cleaning up old backups (older than $BACKUP_RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true

# ============================================
# GIT OPERATIONS
# ============================================
log_step "Fetching latest code from Git..."

# Store current commit for comparison
OLD_COMMIT=$(git rev-parse --short HEAD)

# Fetch latest changes
log_info "Fetching changes from remote..."
git fetch origin "$BRANCH"

# Check if there are any changes
if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/$BRANCH)" ]; then
    log_warn "No new changes detected. Deployment not necessary."
    read -p "Do you want to rebuild anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled."
        exit 0
    fi
fi

# Show what's changed
log_info "Changes to be deployed:"
git log --oneline HEAD..origin/$BRANCH --pretty=format:"  - %h %s (%an)" | head -10

# Pull latest changes
log_info "Pulling latest changes..."
git pull origin "$BRANCH"

NEW_COMMIT=$(git rev-parse --short HEAD)

if [ "$OLD_COMMIT" != "$NEW_COMMIT" ]; then
    log_info "Updated from commit $OLD_COMMIT to $NEW_COMMIT"
else
    log_info "No git changes, but proceeding with rebuild..."
fi

# ============================================
# STOP CONTAINERS
# ============================================
log_step "Stopping current containers..."

# Stop containers gracefully
docker compose -f "$COMPOSE_FILE" down

log_info "Containers stopped successfully"

# ============================================
# REBUILD AND START
# ============================================
log_step "Building new Docker images..."

# Build with no cache to ensure fresh build
docker compose -f "$COMPOSE_FILE" build --no-cache

if [ $? -ne 0 ]; then
    log_error "Build failed! Rolling back..."
    
    # Rollback git changes
    git reset --hard "$OLD_COMMIT"
    
    # Start old version
    docker compose -f "$COMPOSE_FILE" up -d
    
    log_error "Rollback completed. Please check the error logs."
    exit 1
fi

log_info "Build completed successfully"

# ============================================
# START CONTAINERS
# ============================================
log_step "Starting containers..."

docker compose -f "$COMPOSE_FILE" up -d

if [ $? -ne 0 ]; then
    log_error "Failed to start containers! Check logs."
    exit 1
fi

log_info "Containers started successfully"

# ============================================
# VERIFY DEPLOYMENT
# ============================================
log_step "Verifying deployment..."

# Wait for services to be ready
log_info "Waiting for services to initialize (30 seconds)..."
sleep 30

# Check container status
log_info "Checking container status..."
docker compose -f "$COMPOSE_FILE" ps

# Health check
log_info "Running health checks..."
HEALTH_CHECK_PASSED=false

if command -v curl &> /dev/null; then
    for i in {1..10}; do
        if curl -sf http://localhost:3000/health > /dev/null; then
            log_info "✅ Health check passed!"
            HEALTH_CHECK_PASSED=true
            break
        else
            log_warn "Health check attempt $i/10 failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    if [ "$HEALTH_CHECK_PASSED" = false ]; then
        log_error "Health checks failed! Application might not be working correctly."
        log_warn "Check logs with: ./logs.sh"
        
        # Ask if rollback is needed
        read -p "Do you want to rollback to previous version? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Rolling back..."
            docker compose -f "$COMPOSE_FILE" down
            git reset --hard "$OLD_COMMIT"
            docker compose -f "$COMPOSE_FILE" up -d --build
            log_info "Rollback completed"
        fi
        exit 1
    fi
else
    log_warn "curl not installed. Skipping health check."
fi

# ============================================
# CLEANUP
# ============================================
log_step "Cleaning up..."

# Remove dangling images
log_info "Removing unused Docker images..."
docker image prune -f > /dev/null 2>&1

# ============================================
# DEPLOYMENT COMPLETE
# ============================================
echo ""
echo "============================================"
log_info "🎉 Deployment completed successfully!"
echo "============================================"
echo ""
echo "📊 Deployment Summary:"
echo "  - Previous commit: $OLD_COMMIT"
echo "  - New commit:      $NEW_COMMIT"
echo "  - Backup location: $CURRENT_BACKUP"
echo "  - Deployment time: $(date)"
echo ""
echo "🐳 Container Status:"
docker compose -f "$COMPOSE_FILE" ps
echo ""
echo "📝 Useful commands:"
echo "  - View logs:       ./logs.sh"
echo "  - Check status:    ./status.sh"
echo "  - Restart:         ./restart.sh"
echo ""
echo "🌐 Application is running at: http://localhost:3000"
echo ""
