#!/bin/bash
set -e

echo "=========================================="
echo "  rConfig v8 Core - Starting"
echo "=========================================="

# Wait for database to be ready
echo "⏳ Waiting for database..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done
echo "✅ Database is ready!"

# Create .env if it doesn't exist
if [ ! -f /var/www/html/rconfig/.env ]; then
    echo "📝 Creating .env file from example..."
    cp /var/www/html/rconfig/.env.example /var/www/html/rconfig/.env
fi

# Run composer dump-autoload to complete package discovery (skipped during build)
echo "🔧 Running composer autoload dump..."
cd /var/www/html/rconfig
composer dump-autoload --optimize 2>/dev/null || echo "   (Autoload already optimized)"

if ! grep -q "APP_KEY=base64:" /var/www/html/rconfig/.env; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Set correct permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data /var/www/html/rconfig/storage
chown -R www-data:www-data /var/www/html/rconfig/bootstrap/cache
chmod -R 775 /var/www/html/rconfig/storage
chmod -R 775 /var/www/html/rconfig/bootstrap/cache

if [ -f /var/www/html/rconfig/storage/oauth-private.key ]; then
    echo "🔐 Setting OAuth key permissions..."
    chmod 600 /var/www/html/rconfig/storage/oauth-private.key
    chmod 600 /var/www/html/rconfig/storage/oauth-public.key
    chown www-data:www-data /var/www/html/rconfig/storage/oauth-private.key
    chown www-data:www-data /var/www/html/rconfig/storage/oauth-public.key
fi

# Check if first-time installation
if [ ! -f /var/www/html/rconfig/.installed ]; then
    echo "⚠️  First-time installation detected."
    echo "   Please run: docker compose exec app php artisan v8core:install"
    touch /var/www/html/rconfig/.installed
else
    echo "🔄 Running migrations..."
    php artisan migrate --force 2>/dev/null || echo "   (No new migrations)"
fi

echo "🚀 Starting services..."
echo "=========================================="

#Hand off to container CMD (supervisord by default)
exec "$@"
