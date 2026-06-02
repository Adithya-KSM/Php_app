#!/bin/bash
set -e

echo "Configuring Laravel..."

cd /var/www/html

if [ ! -f .env ]; then
    cp .env.example .env
fi

sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
sed -i 's/DB_HOST=.*/DB_HOST=adithya-manual-db-ror.chm62iqq6l1r.ap-south-1.rds.amazonaws.com/' .env
sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE=laravel/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=admin/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=AdithyaDB/' .env
sed -i 's|APP_URL=.*|APP_URL=https://myphp.adithyaksm.tech|' .env

echo "Generating app key..."
php artisan key:generate --force

echo "Clearing config..."
php artisan config:clear

echo "Caching config..."
php artisan config:cache

echo "Configuring PHP-FPM..."
sed -i 's|listen = /run/php/php8.4-fpm.sock|listen = 127.0.0.1:9000|g' /etc/php/8.4/fpm/pool.d/www.conf

service php8.4-fpm start
nginx -g 'daemon off;'
