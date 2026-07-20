#!/bin/bash
set -e

echo "Configuring Laravel Application Environment..."

# Navigate to the application root directory
cd /var/www/html

# Generate the initial .env file if it does not exist from an example template
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
fi

# 1. Dynamically loop over and write environment variables passed down by AWS ECS
echo "Injecting ECS environment variables into local config..."
for var in DB_CONNECTION DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD APP_URL; do
    if [ ! -z "${!var}" ]; then
        sed -i "s|^${var}=.*|${var}=${!var}|" .env || echo "${var}=${!var}" >> .env
    fi
done

# Force Laravel logging to write to file storage instead of stderr/stdout
sed -i 's|^LOG_CHANNEL=.*|LOG_CHANNEL=single|' .env || echo "LOG_CHANNEL=single" >> .env

# 2. Fail early if the core APP_KEY wasn't provided in the Task Definition
if [ -z "${APP_KEY}" ]; then
    echo "CRITICAL ERROR: APP_KEY environment variable is missing from the ECS Task Definition!"
    exit 1
fi

# 3. Securely match or append the immutable APP_KEY variable safely
grep -q "^APP_KEY=" .env \
  && sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env \
  || echo "APP_KEY=${APP_KEY}" >> .env

# 4. Clear existing cache artifacts and rebuild optimal config matrices
echo "Optimizing and caching Laravel configuration frameworks..."
php artisan route:clear
php artisan view:clear
php artisan config:clear
php artisan config:cache

# 5. Transition PHP-FPM pool settings from standard socket layer to TCP port binding
echo "Configuring PHP-FPM for network port mapping..."
sed -i 's|listen = /run/php/php8.4-fpm.sock|listen = 127.0.0.1:9000|g' /etc/php/8.4/fpm/pool.d/www.conf

# 6. Start CloudWatch Agent in background mode
echo "Starting CloudWatch Agent inside container..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# 7. Kickstart internal processing engines
echo "Starting application worker engines..."
service php8.4-fpm start

echo "Handing control over to Nginx..."
nginx -g 'daemon off;'