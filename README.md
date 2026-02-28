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

# 3. Build and start
docker compose build
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
APP_URL=http://your-server-ip:8080
APP_DIR_PATH=/var/www/html/rconfig

DB_HOST=db
DB_PORT=3306
DB_DATABASE=rconfig
DB_USERNAME=rconfig_user
DB_PASSWORD=your_secure_password

```

### Step 3: Build and Start

```bash
docker compose build
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

### Automated (Recommended)

```bash
chmod +x update.sh
./update.sh
```

### Manual

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
docker compose exec app php artisan migrate --force
docker compose exec app php artisan rconfig:clear-all
```

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

If the socket is missing, rebuild so the updated supervisor config is used:

```bash
docker compose up -d --build
```

### Redis Bind Error

**Symptoms:** `bind: Address already in use` for port `6379`

Redis must only be managed by one process. This image uses Supervisor as the single
process owner for Redis.

### Missing APP_KEY Error

**Symptoms:** "No application encryption key has been specified"

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
A: No! Dockerfile clones it automatically.

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

**Fix:**

```bash
docker compose exec app php artisan key:generate --force
docker compose restart app
```

**Note:** The entrypoint automatically generates this on first start, but if you encounter this error, run the command above.