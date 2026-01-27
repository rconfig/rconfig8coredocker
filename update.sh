#!/bin/bash

# rConfig V8 Core Docker Update Script
# Updates rConfig to latest version from GitHub

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

# Stop containers
echo "🛑 Stopping containers..."
$DC down

# Rebuild images (this will clone latest rConfig from GitHub)
echo "🔨 Rebuilding Docker images with latest rConfig..."
echo "   (This will clone the latest code from GitHub)"
$DC build --no-cache

# Start containers
echo "🚀 Starting containers..."
$DC up -d

# Wait for containers to be ready
echo "⏳ Waiting for containers to start..."
sleep 15

# Run migrations
echo "🔄 Running database migrations..."
$DC exec app php artisan migrate --force

# Clear caches
echo "🗑️  Clearing caches..."
$DC exec app php artisan cache:clear
$DC exec app php artisan config:clear
$DC exec app php artisan view:clear

# Restart Horizon
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
