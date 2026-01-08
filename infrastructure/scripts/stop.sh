#!/bin/bash
# Stop all containers
echo "Stopping containers..."
APP_DIR="$HOME/app"  # Application directory
COMPOSE_FILE="infrastructure/docker-compose.yml"
cd "$APP_DIR" || {
    echo "Failed to navigate to $APP_DIR"
    exit 1
}
docker compose -f "$COMPOSE_FILE" down
echo "Done!"
