# rConfig V8 Core - Docker Image
# Official Docker image for rConfig V8 Core open-source edition
FROM php:8.4-apache

# Set user ID for www-data to 1000
RUN usermod -u 1000 www-data

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    default-libmysqlclient-dev \
    zip \
    vim \
    redis-server \
    unzip \
    supervisor \
    cron \
    netcat-openbsd \
    libsnmp-dev \
    snmp \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure zip \
    && docker-php-ext-install gd zip pdo pdo_mysql pcntl snmp \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module
RUN a2enmod rewrite

# Create application directory
RUN mkdir -p /var/www/html/rconfig

# Set working directory
WORKDIR /var/www/html/rconfig

# Clone rConfig from GitHub (uses main branch by default, supports PHP 8.4)
ARG RCONFIG_VERSION=main
RUN git clone --branch ${RCONFIG_VERSION} --depth 1 https://github.com/rconfig/rconfig.git . \
    && rm -rf .git

# Configure Apache to use Laravel's public directory
RUN echo "DocumentRoot /var/www/html/rconfig/public" > /etc/apache2/sites-available/000-default.conf \
    && echo "<Directory /var/www/html/rconfig/public>" >> /etc/apache2/sites-available/000-default.conf \
    && echo "    AllowOverride All" >> /etc/apache2/sites-available/000-default.conf \
    && echo "    Require all granted" >> /etc/apache2/sites-available/000-default.conf \
    && echo "</Directory>" >> /etc/apache2/sites-available/000-default.conf

# Install Composer
COPY --from=composer:2.4 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies (skip scripts to avoid database connection during build)
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --no-scripts --optimize-autoloader --no-interaction

# Copy the supervisord configuration file
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create log directory and set permissions
RUN mkdir -p /var/log && chown -R www-data:www-data /var/log

# Set up permissions for storage and cache
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/rconfig/storage /var/www/html/rconfig/bootstrap/cache \
    && chmod -R 775 /var/www/html/rconfig/storage /var/www/html/rconfig/bootstrap/cache

# Expose port 80
EXPOSE 80

# Use entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start supervisord
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
