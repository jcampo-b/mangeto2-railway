#FORKED By Braintly

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

## 4. Railway template setup

When building a template in the [Railway Template Composer](https://docs.railway.com/templates/create), use **template variable functions** to generate secrets and **reference variables** so Magento gets the same credentials as Elasticsearch.

### Elasticsearch service

- **Root Directory**: `elasticsearch` (this repo).
- **Volume**: Attach a volume with mount path `/esdata`.
- **Variables** (same as the [Railway Elasticsearch template](https://github.com/railwayapp-templates/elasticsearch)):

| Variable            | Value              | Description |
|---------------------|--------------------|-------------|
| `ELASTIC_PASSWORD`  | `${{secret(32)}}`  | Random password for user `elastic`; generated once per deploy. |
| `ELASTIC_USERNAME`  | `elastic`          | Built-in superuser username. |
| `ES_JAVA_OPTS`      | `-Xms500m -Xmx4g`  | JVM heap (min 500m, max 4g). |
| `PORT`              | `9200`             | HTTP port; Railway exposes the service on this port. |

### Magento service

Reference the Elasticsearch service so Magento uses the same password and host:

| Variable                  | Value |
|---------------------------|--------|
| `ELASTICSEARCH_PASSWORD`  | `${{Elasticsearch.ELASTIC_PASSWORD}}` |
| `ELASTICSEARCH_HOST`      | `${{Elasticsearch.RAILWAY_PRIVATE_DOMAIN}}` (or the Elasticsearch service's private hostname) |
| `ELASTICSEARCH_PORT`      | `9200` (or the port exposed by Elasticsearch) |
| `ELASTICSEARCH_USERNAME`  | `elastic` |

Use your MySQL and admin variables as usual (e.g. `MYSQL_HOST`, `MYSQL_PASSWORD`, `ADMIN_PASSWORD`). For MySQL you can also use `${{MySQL.RAILWAY_PRIVATE_DOMAIN}}` and `${{MySQL.MYSQL_PASSWORD}}` if the service names match.

---

## 5. Required environment variables (Railway)

For the Magento service, set at least:

| Variable          | Description                |
|-------------------|----------------------------|
| `MYSQL_HOST`      | MySQL server host          |
| `MYSQL_PORT`      | MySQL port                 |
| `MYSQL_USER`      | MySQL user                 |
| `MYSQL_PASSWORD`  | MySQL password             |
| `MYSQL_DATABASE`  | Database name              |

For OpenSearch/Elasticsearch (used at install): `ELASTICSEARCH_HOST`, `ELASTICSEARCH_PORT`, `ELASTICSEARCH_PASSWORD`, and optionally auth and index prefix. For admin account: `ADMIN_PASSWORD` (and optionally `ADMIN_EMAIL`, etc.). See `docker/entrypoint.sh` for the full list and defaults.

---

## 6. Summary

| Scenario              | Behavior                                                                 |
|-----------------------|--------------------------------------------------------------------------|
| **Volume empty**      | Copy Magento from `/opt/magento` in the image to `/var/www/html`.        |
| **MySQL has no store table** | Run `setup:install` with MySQL + OpenSearch, then reindex and production setup. |
| **MySQL already has Magento** | Skip install; only fix permissions and optional sample data.             |
| **INSTALL_SAMPLE_DATA=true** | Clone magento2-sample-data, build, upgrade, deploy, copy media.          |

Magento is installed from the **magento/magento2** GitHub tag (ZIP + Composer). Sample data, when requested, comes from **magento/magento2-sample-data** (branch 2.4).

