FROM nginx:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install PHP and required extensions
RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    php-mysql \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-bcmath \
    php-cli \
    php-common \
    php-opcache \
    unzip \
    curl \
    git \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Remove default nginx site
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy Laravel application
COPY . /var/www/html

WORKDIR /var/www/html

# Install Laravel dependencies
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --prefer-dist

# Remove old cache files
RUN rm -rf bootstrap/cache/*.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Copy startup script
COPY start.sh /start.sh

RUN chmod +x /start.sh

# Container health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80

CMD ["/start.sh"]
