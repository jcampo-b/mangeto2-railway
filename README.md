# Magento 2 with MySQL 8 and Elasticsearch for Railway

Magento 2.4 stack designed to run on [Railway](https://railway.com): web app (Nginx + PHP-FPM), MySQL 8, and Elasticsearch as separate services.

---

## 1. Overview

- **Magento**: 2.4.x (default tag: `2.4.7-p3`), served by Nginx and PHP 8.2-FPM.
- **MySQL**: 8.0 (officially supported for Magento 2.4), run as a separate Railway service.
- **Search**: Elasticsearch, configured via environment variables at install time.

The app listens on the port provided by Railway (`PORT`, default 8080).

---

## 2. Installation sources

### Magento core

- **Source**: [magento/magento2](https://github.com/magento/magento2) on GitHub.
- **Method**: The Docker image downloads the release ZIP for the chosen tag (e.g. `2.4.7-p3`) from GitHub and runs `composer install` (no dev dependencies).
- **Version**: Controlled by build arg `MAGENTO_VERSION_TAG` in the Dockerfile (default: `2.4.7-p3`).

### Sample data (optional)

- **Source**: [magento/magento2-sample-data](https://github.com/magento/magento2-sample-data), branch `2.4`.
- **Method**: When `INSTALL_SAMPLE_DATA=true`, the entrypoint clones this repo (depth 1) and runs the sample data build script against the installed Magento root, then runs `setup:upgrade`, static content deploy, and copies sample media.

---

## 3. How installation works

Startup is handled by `docker/entrypoint.sh`. Two main cases are covered: **empty volume** and **empty MySQL**.

### 3.1 When the volume is empty

The app uses a writable volume at `/var/www/html`. If that volume is new, it has no Magento files.

- **Check**: The script looks for `bin/magento` under `/var/www/html`.
- **If missing**: The image keeps a copy of the fully built Magento (after `composer install`) in `/opt/magento`. The entrypoint copies that copy into `/var/www/html` so you get a working Magento tree and `bin/magento` without re-downloading or re-running Composer.
- After that, the same container continues with the MySQL/install logic below.

So: **empty volume** → populate from image; **existing volume** → leave files as-is and only run install/setup if needed.

### 3.2 When MySQL has no Magento data (fresh database)

Magento’s installation is run only when the database does not already contain Magento tables.

- **Check**: The script uses PHP to connect to MySQL and run `SHOW TABLES LIKE 'store'`. If that query returns no rows, the database is treated as “not installed.”
- **If not installed** and there is no valid `app/etc/env.php` (or it’s empty), the entrypoint runs:
  - `php bin/magento setup:install` with:
    - MySQL connection from `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`
    - OpenSearch/Elasticsearch from `ELASTICSEARCH_*` / `opensearch-*` variables
    - Admin user from `ADMIN_*` variables
    - Base URL from `BASE_URL`
  - Then: reindex (e.g. `catalogsearch_fulltext`), cache flush, switch to production mode, deploy static content, and apply store base URL and secure settings.

So: **no Magento tables in MySQL** → full `setup:install` plus reindex and production setup; **tables already exist** → no install, only optional sample data and permission fixes.

### 3.3 Optional: sample data

- **When**: Only if `INSTALL_SAMPLE_DATA` is set to a “true” value (e.g. `true`, `yes`, `1`) and `app/etc/env.php` exists and sample data is not already present (e.g. no `app/code/Magento/ThemeSampleData`).
- **What**: Clone `magento/magento2-sample-data` (branch 2.4), run the sample data build script with `--ce-source="/var/www/html"`, then `setup:upgrade`, `setup:di:compile`, static content deploy, cache flush, and copy sample media into `pub/media`.

---
"# mangeto2-railway" 
