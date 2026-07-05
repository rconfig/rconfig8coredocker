# rConfig v8 Core - Docker Setup

Official Docker deployment for [rConfig v8 Core](https://github.com/rconfig/rconfig) - Open Source Network Configuration Management.

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![PHP](https://img.shields.io/badge/php-%23777BB4.svg?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net/)
[![Laravel](https://img.shields.io/badge/laravel-%23FF2D20.svg?style=for-the-badge&logo=laravel&logoColor=white)](https://laravel.com/)

## 🚀 Quick Start

Get rConfig running in **5 minutes**:

```bash
# 1. Clone this repository
git clone https://github.com/rconfig/rconfig8coredocker.git
cd rconfig8coredocker

# 2. Create environment file
cp .env.example .env
vi .env  # Edit with your settings

# 3. Pull the prebuilt image and start
docker compose pull
docker compose up -d

# 4. Install rConfig
docker compose exec app php artisan v8core:install

# 5. Access rConfig
# http://localhost:8080
# Login: admin@domain.com / admin
```

**⚠️ Change default credentials immediately after first login!**

---

## 📋 What's Included

- **PHP 8.4** with all required extensions
- **Apache 2.4** pre-configured for Laravel
- **MariaDB 10.11** database server
- **Redis** for queues and caching
- **Laravel Horizon** queue management with dashboard
- **Supervisor** managing all services automatically

---

## 📦 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- 2GB RAM minimum
- Port 8080 available

---

## 🛠️ Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/rconfig/rconfig8coredocker.git
cd rconfig8coredocker
```

### Step 2: Configure Environment

```bash
cp .env.example .env
vi .env
```

**Required settings:**

```env
# Which prebuilt release to run (see Docker Hub tags). Pin it for production.
RCONFIG_VERSION=8.3.0

APP_URL=http://your-server-ip:8080

DB_DATABASE=rconfig
DB_USERNAME=rconfig_user
DB_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_secure_root_password
```

> Storage (device config backups, logs, keys) persists in the `storage_data`
> Docker volume by default. To keep it on a visible host path instead, switch to
> the bind mount option in `docker-compose.yml`.

### Step 3: Pull and Start

The image is prebuilt and published on Docker Hub, so there is nothing to
compile. `RCONFIG_VERSION` in your `.env` selects which release to run.

```bash
docker compose pull
docker compose up -d
```

### Step 4: Install rConfig

```bash
docker compose exec app php artisan v8core:install
```

### Step 5: Access Application

```
http://localhost:8080
```

**Default Login:**
- Email: `admin@domain.com`
- Password: `admin`

🔒 **Change immediately after first login!**

---

## ✅ Post-Installation

### Verify Services

```bash
docker compose exec app supervisorctl status
```

All services should show **RUNNING**.

If you see an application setup screen or first-run errors, complete install:

```bash
docker compose exec app php artisan v8core:install
```

Docker persists install state in the storage volume. After `php artisan v8core:install`,
the container will detect the installed database and create `storage/.installed`
automatically.


### Change Admin Credentials

1. Login with default credentials
2. Go to **Settings** → **Users**
3. Update email and password

---

## 🔄 Common Operations

### View Logs

```bash
docker compose logs -f app
docker compose exec app tail -f /var/www/html/rconfig/storage/logs/laravel.log
```

### Run Artisan Commands

```bash
docker compose exec app php artisan [command]
```

### Restart

```bash
docker compose restart app
```

---

## 🔄 Updates

Upgrading pulls a newer prebuilt image, so there is no rebuild. The container
rebuilds its own caches on start, so no manual cache clear is needed.

### Automated (Recommended)

```bash
chmod +x update.sh
./update.sh
```

### Manual

```bash
# 1. Set RCONFIG_VERSION in .env to the release you want (or leave "latest").
# 2. Pull and restart:
docker compose pull
docker compose up -d

# 3. Apply any new database migrations:
docker compose exec app php artisan migrate --force
```

Always back up the database before upgrading (see Backup below).

### Upgrading from a build-based install

Earlier versions of this kit built the image locally (`docker compose build`).
Moving to the prebuilt image keeps all your data, because the volume names are
unchanged:

```bash
# 1. Pull the latest kit (this compose file, .env.example, update.sh).
git pull

# 2. Add a version pin to your existing .env (or set it to latest):
echo "RCONFIG_VERSION=8.3.0" >> .env

# 3. Pull the image and restart. Your db_data and storage_data volumes,
#    and your .env with its APP_KEY, carry over untouched.
docker compose pull
docker compose up -d
docker compose exec app php artisan migrate --force
```

The old locally built image and the now-unused `bootstrap_cache` volume can be
cleaned up afterwards with `docker image prune` and `docker volume rm`.

---

## 💾 Backup

```bash
# Backup database
docker compose exec -T db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${DB_DATABASE} > backup-$(date +%Y%m%d).sql
```

### Restore

```bash
docker compose stop app
docker compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ${DB_DATABASE} < backup.sql
docker compose start app
```

---

## 🐛 Troubleshooting

### Permission Errors

```bash
docker compose exec app chown -R www-data:www-data /var/www/html/rconfig/storage
docker compose exec app chmod -R 775 /var/www/html/rconfig/storage
docker compose exec app php artisan rconfig:clear-all
```

### Database Connection

```bash
docker compose ps db  # Check database is healthy
sleep 30 && docker compose restart app  # Wait and restart
```

### Horizon Not Processing

```bash
docker compose exec app php artisan horizon:status
docker compose exec app supervisorctl restart horizon
```

### Supervisor Socket Error

**Symptoms:** `unix:///var/run/supervisor.sock no such file`

```bash
docker compose exec app supervisorctl status
docker compose exec app ls -l /var/run/supervisor/supervisor.sock
```

If the socket is missing, recreate the container so it starts cleanly:

```bash
docker compose up -d --force-recreate app
```

### Redis Bind Error

**Symptoms:** `bind: Address already in use` for port `6379`

Redis must only be managed by one process. This image uses Supervisor as the single
process owner for Redis.

### Missing APP_KEY Error

**Symptoms:** "No application encryption key has been specified"

For an existing installation, restore the original `.env` file or original
`APP_KEY`. Do not generate a new `APP_KEY` for an existing database, because
encrypted values such as device credentials may no longer decrypt.

For a new installation only:

```bash
docker compose exec app php artisan key:generate --force
docker compose restart app
```

### OAuth Key Permission Errors

**Symptoms:** "Key file permissions are not correct"

```bash
docker compose exec app bash -c "chmod 600 /var/www/html/rconfig/storage/oauth-*.key && chown www-data:www-data /var/www/html/rconfig/storage/oauth-*.key"
docker compose restart app
```

---

## 🔒 Security

### Production Checklist

- ✅ Change all default passwords
- ✅ Set `APP_DEBUG=false`
- ✅ Use strong passwords
- ✅ Enable firewall
- ✅ Set up SSL/TLS
- ✅ Regular backups

### Change Port

Edit `.env`:
```env
APP_PORT=9090
```

Restart:
```bash
docker compose down && docker compose up -d
```

---

## 📚 Resources

- **Main Repo:** [github.com/rconfig/rconfig](https://github.com/rconfig/rconfig)
- **Docs:** [v8coredocs.rconfig.com](https://v8coredocs.rconfig.com)
- **Support:** [github.com/rconfig/rconfig/issues](https://github.com/rconfig/rconfig/issues)
- **YouTube:** [youtube.com/rconfigv8Core](https://www.youtube.com/channel/rconfigv8Core)

---

## ❓ FAQ

**Q: Do I need to clone the main rconfig repo?**  
A: No. You run a prebuilt image from Docker Hub (`rconfig/rconfig`). You only
clone this kit for the `docker-compose.yml` and `.env`.

**Q: Can I run multiple instances?**  
A: Yes! Use different directories and ports.

**Q: How to enable debug mode?**  
```bash
# Edit .env: APP_DEBUG=true
docker compose down && docker compose up -d
docker compose exec app php artisan config:clear
```

**Q: External database?**  
A: Remove `db` service from docker-compose.yml, update `.env`.

---

## 🤝 Contributing

Pull requests welcome! Please test thoroughly before submitting.

---

## 📄 License

Follows rConfig v8 Core license.

---

**Made with ❤️ for the rConfig community**

⭐ Star us on GitHub if this helped you!

### Missing Application Key

**Symptoms:** "No application encryption key has been specified"

For an existing installation, restore the original `.env` file or original
`APP_KEY`. Only generate a new key for a brand-new install with no existing
encrypted data.

```bash
docker compose exec app php artisan key:generate --force
docker compose restart app
```

**Note:** The entrypoint automatically generates this on first start when
`.env` is present but `APP_KEY` is empty.
