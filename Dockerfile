# Start from the official PHP-FPM base image for precise version control
FROM php:8.3-fpm

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Nginx, CloudWatch Agent, and system build tools
RUN apt-get update && apt-get install -y \
    nginx \
    unzip \
    curl \
    git \
    wget \
    gnupg \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    && wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
    && dpkg -i -E ./amazon-cloudwatch-agent.deb \
    && rm -f ./amazon-cloudwatch-agent.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Install official PHP extensions safely
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# 3. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Copy configurations
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 5. Set up app directory and log files
WORKDIR /var/www/html
COPY . /var/www/html

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist \
    && rm -rf bootstrap/cache/*.php \
    && mkdir -p /var/log/nginx /var/www/html/storage/logs \
    && touch /var/log/nginx/access.log /var/log/nginx/error.log /var/www/html/storage/logs/laravel.log \
    && chown -R www-data:www-data /var/www/html /var/log/nginx \
    && chmod -R 775 storage bootstrap/cache /var/log/nginx

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]