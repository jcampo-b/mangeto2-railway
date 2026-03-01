# Magento 2.4 web (Nginx + PHP-FPM) for Railway
# MySQL and Elasticsearch run as separate services on Railway

FROM php:8.2-fpm-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# PHP extensions required for Magento 2.4 (and dependencies)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nginx \
    git \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libssl-dev \
    unzip \
    cron \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        intl \
        pdo_mysql \
        soap \
        xsl \
        zip \
        gd \
        opcache \
        sockets \
        pcntl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer globally
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

# Recommended php.ini for Magento
RUN { \
    echo 'memory_limit=2G'; \
    echo 'max_execution_time=1800'; \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.max_accelerated_files=20000'; \
    } > /usr/local/etc/php/conf.d/99-magento.ini

# Nginx: config is overridden at runtime to use PORT
RUN rm -f /etc/nginx/sites-enabled/default
COPY docker/nginx-magento.conf /etc/nginx/sites-available/magento.conf
RUN ln -sf /etc/nginx/sites-available/magento.conf /etc/nginx/sites-enabled/magento.conf

COPY docker/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /var/www/html

# Magento version/tag from GitHub (public ZIP, no .git)
ARG MAGENTO_VERSION_TAG=2.4.7-p3

# Download tag from GitHub and run composer install
RUN curl -fsSL "https://codeload.github.com/magento/magento2/zip/refs/tags/${MAGENTO_VERSION_TAG}" -o /tmp/magento.zip \
    && unzip -q /tmp/magento.zip -d /tmp \
    && cp -r "/tmp/magento2-${MAGENTO_VERSION_TAG}"/. /var/www/html/ \
    && rm -rf /tmp/magento.zip "/tmp/magento2-${MAGENTO_VERSION_TAG}" \
    && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --prefer-dist --no-interaction

# Permissions for var/ and pub/ (Magento needs to write)
RUN mkdir -p /var/www/html/var /var/www/html/pub/static /var/www/html/pub/media \
    && chown -R www-data:www-data /var/www/html/var /var/www/html/pub/static /var/www/html/pub/media 2>/dev/null || true

# Copy Magento to /opt/magento so we can populate an empty volume on first run
RUN cp -r /var/www/html/. /opt/magento/

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
