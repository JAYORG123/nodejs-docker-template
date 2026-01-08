#!/bin/bash
# Check container status
echo "=== Container Status ==="
APP_DIR="$HOME/app"  # Application directory
COMPOSE_FILE="infrastructure/docker-compose.yml"
cd "$APP_DIR" || {
    echo "Failed to navigate to $APP_DIR"
    exit 1
}
docker compose -f "$COMPOSE_FILE" ps
echo ""
echo "=== Application Health ==="
curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
