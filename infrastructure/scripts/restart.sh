#!/bin/bash

# Restart containers
echo "Restarting containers..."
APP_DIR="$HOME/app"  # Application directory
COMPOSE_FILE="infrastructure/docker-compose.yml"
cd "$APP_DIR" || {
    echo "Failed to navigate to $APP_DIR"
    exit 1
}
docker compose -f "$COMPOSE_FILE" restart
echo "Done!"
