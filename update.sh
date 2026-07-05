#!/bin/bash

# rConfig V8 Core Docker Update Script
# Pulls the target prebuilt image and applies migrations. No local rebuild.

set -e

echo "============================================"
echo "  rConfig V8 Core - Update Script"
echo "============================================"
echo ""

# Check if docker compose is available
if command -v docker-compose &> /dev/null; then
    DC="docker-compose"
elif docker compose version &> /dev/null; then
    DC="docker compose"
else
    echo "❌ Error: Docker Compose not found"
    exit 1
fi

# Show the version that will be pulled (from .env, defaults to latest).
if [ -f .env ]; then
    VERSION=$(grep -E '^RCONFIG_VERSION=' .env | cut -d= -f2)
fi
echo "📦 Target image: rconfig/rconfig:${VERSION:-latest}"
echo "   (edit RCONFIG_VERSION in .env to change this)"
echo ""

# Backup database
read -p "📦 Create database backup before updating? (recommended) [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "💾 Creating backup..."
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    $DC exec -T db mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-root_password} ${DB_DATABASE:-rconfig} > "$BACKUP_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Backup saved to: $BACKUP_FILE"
    else
        echo "⚠️  Backup failed, but continuing..."
    fi
    echo ""
fi

# Pull the target image
echo "⬇️  Pulling image..."
$DC pull

# Recreate the app container on the new image. The entrypoint rebuilds the
# config/route/view caches on start, so no manual cache clear is required.
echo "🚀 Starting containers..."
$DC up -d

# Wait for the app to come back up
echo "⏳ Waiting for containers to start..."
sleep 15

# Run migrations
echo "🔄 Running database migrations..."
$DC exec app php artisan migrate --force

# Reload Horizon workers so they run the new code
echo "🔄 Restarting Horizon..."
$DC exec app php artisan horizon:terminate

echo ""
echo "============================================"
echo "  ✅ Update Complete!"
echo "============================================"
echo ""
echo "🌐 Access rConfig at: http://localhost:8080"
echo "📊 Horizon Dashboard: http://localhost:8080/horizon"
echo "📊 View logs: $DC logs -f app"
echo ""
