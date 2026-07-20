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

# 5. Dynamically configure and start PHP-FPM regardless of exact PHP version
PHP_FPM_CONF=$(find /etc/php -name "www.conf" 2>/dev/null | head -n 1)

if [ -f "$PHP_FPM_CONF" ]; then
    echo "Found PHP-FPM pool config at $PHP_FPM_CONF"
    sed -i 's/listen = \/run\/php\/php.*-fpm.sock/listen = 9000/' "$PHP_FPM_CONF" || true
else
    echo "PHP-FPM config www.conf not found, skipping FPM tuning."
fi

# 6. Start CloudWatch Agent in background mode (if installed)
if [ -f "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl" ]; then
    echo "Starting CloudWatch Agent inside container..."
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
        -s || echo "CloudWatch agent warning: could not start."
fi

# 7. Start PHP-FPM dynamically or fall back gracefully
echo "Starting PHP-FPM service..."
FPM_SERVICE=$(ls /etc/init.d/php* 2>/dev/null | head -n 1)

if [ -n "$FPM_SERVICE" ]; then
    $FPM_SERVICE start
else
    # Fallback if no init.d script exists
    php-fpm -D || service php-fpm start || echo "PHP-FPM started via daemon"
fi

echo "Handing control over to Nginx..."
exec nginx -g 'daemon off;'