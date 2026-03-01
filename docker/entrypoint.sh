#!/bin/sh
set -e

# Railway injects PORT; default 8080
PORT="${PORT:-8080}"

# Set port in Nginx config
sed -i "s/listen [0-9]\+/listen ${PORT}/" /etc/nginx/sites-available/magento.conf
sed -i "s/listen \[::\]:[0-9]\+/listen [::]:${PORT}/" /etc/nginx/sites-available/magento.conf

# PHP-FPM in background (before any Magento command)
php-fpm -D

cd /var/www/html

# --- When volume is empty: populate from image so bin/magento and app/ exist ---
if [ ! -f bin/magento ]; then
    echo "Volume empty: copying Magento from image to /var/www/html..."
    cp -r /opt/magento/. /var/www/html/
    rm -rf /opt/magento
fi

# --- Required MySQL variables (fail fast if missing) ---
missing=""
[ -z "${MYSQL_HOST}" ]     && missing="${missing} MYSQL_HOST"
[ -z "${MYSQL_PORT}" ]     && missing="${missing} MYSQL_PORT"
[ -z "${MYSQL_USER}" ]     && missing="${missing} MYSQL_USER"
[ -z "${MYSQL_PASSWORD}" ] && missing="${missing} MYSQL_PASSWORD"
[ -z "${MYSQL_DATABASE}" ] && missing="${missing} MYSQL_DATABASE"
if [ -n "$missing" ]; then
    echo "Error: required environment variables are not set:$missing"
    exit 1
fi

# --- Check if Magento is already installed (DB has tables) ---
DB_INSTALLED=0
if php -r "
    \$h = getenv('MYSQL_HOST');
    \$p = getenv('MYSQL_PORT');
    \$u = getenv('MYSQL_USER');
    \$pw = getenv('MYSQL_PASSWORD');
    \$db = getenv('MYSQL_DATABASE');
    \$dsn = 'mysql:host='.\$h.';port='.\$p.';dbname='.\$db;
    try {
        \$pdo = new PDO(\$dsn, \$u, \$pw);
        \$r = \$pdo->query(\"SHOW TABLES LIKE 'store'\");
        exit(\$r && \$r->rowCount() > 0 ? 0 : 1);
    } catch (Exception \$e) {
        exit(1);
    }
    " 2>/dev/null; then
    DB_INSTALLED=1
fi

# --- Install only if DB has no Magento tables ---
if [ "$DB_INSTALLED" = "0" ]; then
    if [ ! -f app/etc/env.php ] || [ ! -s app/etc/env.php ]; then
        BASE_URL="${BASE_URL:-https://truthful-healing-production.up.railway.app/}"
        DB_HOST="${MYSQL_HOST}:${MYSQL_PORT}"

        echo "Installing Magento..."
        php bin/magento setup:install \
            --base-url="${BASE_URL}" \
            --db-host="${DB_HOST}" \
            --db-user="${MYSQL_USER}" \
            --db-password="${MYSQL_PASSWORD}" \
            --db-name="${MYSQL_DATABASE}" \
            --search-engine=opensearch \
            --opensearch-host="${ELASTICSEARCH_HOST:-crossover.proxy.rlwy.net}" \
            --opensearch-port="${ELASTICSEARCH_PORT:-16229}" \
            --opensearch-enable-auth="${ELASTICSEARCH_ENABLE_AUTH:-1}" \
            --opensearch-username="${ELASTICSEARCH_USERNAME:-elastic}" \
            --opensearch-password="${ELASTICSEARCH_PASSWORD}" \
            --opensearch-index-prefix="${ELASTICSEARCH_INDEX_PREFIX:-magento2}" \
            --admin-user="${ADMIN_USER:-admin}" \
            --admin-password="${ADMIN_PASSWORD}" \
            --admin-email="${ADMIN_EMAIL:-admin@example.com}" \
            --admin-firstname="${ADMIN_FIRSTNAME:-Admin}" \
            --admin-lastname="${ADMIN_LASTNAME:-User}" \
            --backend-frontname="${BACKEND_FRONTNAME:-admin}"

        echo "Reindexing search and setting up production..."
        php bin/magento indexer:reindex catalogsearch_fulltext || true
        php bin/magento cache:flush
        php bin/magento deploy:mode:set production
        php bin/magento setup:static-content:deploy -f
        php bin/magento config:set dev/static/sign 0
        php bin/magento cron:run
        php bin/magento indexer:set-mode realtime customer_grid
        php bin/magento setup:store-config:set --base-url="${BASE_URL}" --base-url-secure="${BASE_URL}" --use-secure=1 --use-secure-admin=1
        php bin/magento cache:flush
    fi
fi

# --- Optional: install sample data when INSTALL_SAMPLE_DATA=true ---
INSTALL_SAMPLE_DATA="${INSTALL_SAMPLE_DATA:-false}"
case "$INSTALL_SAMPLE_DATA" in
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|1) INSTALL_SAMPLE_DATA=1 ;;
    *) INSTALL_SAMPLE_DATA=0 ;;
esac
if [ "$INSTALL_SAMPLE_DATA" = "1" ] && [ -f app/etc/env.php ] && [ ! -e app/code/Magento/ThemeSampleData ]; then
    echo "INSTALL_SAMPLE_DATA=true: installing sample data..."
    if [ ! -d magento2-sample-data/dev/tools ]; then
        git clone --depth 1 --branch 2.4 https://github.com/magento/magento2-sample-data.git magento2-sample-data
    fi
    ( cd magento2-sample-data && php -f dev/tools/build-sample-data.php -- --ce-source="/var/www/html" )
    php bin/magento setup:upgrade
    php bin/magento setup:di:compile
    php bin/magento setup:static-content:deploy -f
    php bin/magento cache:flush
    rm -rf pub/media/catalog pub/media/downloadable pub/media/wysiwyg
    cp -rL magento2-sample-data/pub/media/catalog \
          magento2-sample-data/pub/media/downloadable \
          magento2-sample-data/pub/media/wysiwyg \
          pub/media/
    echo "Sample data installed."
fi

# Permissions for PHP-FPM user (www-data) on every run
chown -R www-data:www-data /var/www/html/var /var/www/html/generated /var/www/html/pub/static /var/www/html/pub/media 2>/dev/null || true
chmod -R g+w /var/www/html/var /var/www/html/generated /var/www/html/pub/static /var/www/html/pub/media 2>/dev/null || true

# Nginx in foreground (Railway expects main process)
exec nginx -g 'daemon off;'
