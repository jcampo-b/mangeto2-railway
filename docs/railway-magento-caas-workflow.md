# Magento 2 Railway + Braintly CAAS Module — Testing Guide

## Objetivo

Este fork de `magento2-railway` se usa como entorno de prueba en Railway para levantar Magento 2.4.7 y cargar el módulo local:

```txt
app/code/Braintly/Caas
```

El objetivo es poder probar el módulo `Braintly_Caas` dentro de una instalación real de Magento en Railway, sin depender del repo original del template.

---

## Repos involucrados

### 1. Fork Railway Magento

```txt
jcampo-b/mangeto2-railway
```

Este repo contiene:

```txt
Dockerfile
docker/entrypoint.sh
app/code/Braintly/Caas
```

Railway está conectado a este repo y hace deploy automático cuando se pushea a `main`.

### 2. Módulo CAAS original

```txt
Braintly/CAAS-Magento
```

Este repo contiene el código fuente real del módulo Magento.

Para Railway, el módulo se copia dentro del fork como archivos reales en:

```txt
app/code/Braintly/Caas
```

No se usa como submodule en este entorno.

---

## Por qué no usamos submodule

Railway no estaba trayendo correctamente el contenido del submodule durante el build.

Eso provocaba que el módulo se copiara vacío o incompleto dentro de la imagen Docker, y Magento mostraba errores como:

```txt
Unknown module(s): 'Braintly_Caas'
```

Por eso la solución actual es vendorizar/copiar el módulo como archivos reales dentro del fork Railway.

---

## Regla importante

Cuando copies el módulo desde otro repo, asegurate de NO copiar la carpeta `.git`.

Incorrecto:

```txt
app/code/Braintly/Caas/.git
```

Correcto:

```txt
app/code/Braintly/Caas/registration.php
app/code/Braintly/Caas/etc/module.xml
app/code/Braintly/Caas/etc/adminhtml/system.xml
...
```

Si copiás `.git`, Git lo va a detectar como un repo embebido y puede aparecer este warning:

```txt
warning: adding embedded git repository: app/code/Braintly/Caas
```

Eso NO debe pasar.

---

## Cómo actualizar el módulo CAAS en Railway

El módulo `Braintly_Caas` se desarrolla en el repo original:

```txt
Braintly/CAAS-Magento
```

Para probarlo en Railway, el módulo se copia como archivos reales dentro del fork Magento:

```txt
app/code/Braintly/Caas
```

No se usa como submodule en este entorno.

### Script recomendado

Para evitar copiar el módulo manualmente con `rm -rf` + `cp -R`, este repo incluye un script de sincronización:

```txt
scripts/sync-caas-module.sh
```

El script sincroniza el módulo desde una carpeta `src/app` del repo original hacia:

```txt
app/code/Braintly/Caas
```

Usa `rsync --delete` para mantener el destino alineado con el origen y excluye archivos que no deben copiarse:

```txt
.git
.gitmodules
.DS_Store
```

Esto evita el problema de repositorios embebidos dentro de:

```txt
app/code/Braintly/Caas
```

### Uso con path explícito

Desde la raíz del fork `mangeto2-railway`:

```bash
./scripts/sync-caas-module.sh /absolute/path/to/caas-magento-local/src/app
```

Ejemplo local:

```bash
./scripts/sync-caas-module.sh /Users/awesomejohnny/Development/Braintly/caas-magento-local/src/app
```

### Uso con variable de entorno

También se puede configurar una variable de entorno para no pasar el path cada vez:

```bash
export CAAS_MAGENTO_SOURCE_APP=/Users/awesomejohnny/Development/Braintly/caas-magento-local/src/app
./scripts/sync-caas-module.sh
```

### Script

Crear el archivo:

```txt
scripts/sync-caas-module.sh
```

con este contenido:

```bash
#!/usr/bin/env bash

set -euo pipefail

DEFAULT_SOURCE_APP="../caas-magento-local/src/app"
TARGET_APP="app"

SOURCE_APP="${1:-${CAAS_MAGENTO_SOURCE_APP:-$DEFAULT_SOURCE_APP}}"

SOURCE_MODULE="${SOURCE_APP%/}/code/Braintly/Caas"
TARGET_MODULE="${TARGET_APP}/code/Braintly/Caas"

echo "[caas-sync] Syncing Braintly CAAS Magento module"
echo "[caas-sync] Source app: ${SOURCE_APP}"
echo "[caas-sync] Source module: ${SOURCE_MODULE}"
echo "[caas-sync] Target module: ${TARGET_MODULE}"

if [ ! -d "${SOURCE_MODULE}" ]; then
  echo "[caas-sync] ERROR: Source module does not exist."
  echo "[caas-sync] Provide the source app path explicitly:"
  echo "[caas-sync]   ./scripts/sync-caas-module.sh /absolute/path/to/caas-magento-local/src/app"
  echo "[caas-sync] Or set:"
  echo "[caas-sync]   export CAAS_MAGENTO_SOURCE_APP=/absolute/path/to/caas-magento-local/src/app"
  exit 1
fi

if [ ! -f "${SOURCE_MODULE}/registration.php" ]; then
  echo "[caas-sync] ERROR: Missing registration.php in source module."
  exit 1
fi

if [ ! -f "${SOURCE_MODULE}/etc/module.xml" ]; then
  echo "[caas-sync] ERROR: Missing etc/module.xml in source module."
  exit 1
fi

mkdir -p "${TARGET_MODULE}"

rsync -av --delete \
  --exclude='.git' \
  --exclude='.gitmodules' \
  --exclude='.DS_Store' \
  "${SOURCE_MODULE}/" \
  "${TARGET_MODULE}/"

echo "[caas-sync] Verifying target module..."

test -f "${TARGET_MODULE}/registration.php"
test -f "${TARGET_MODULE}/etc/module.xml"

if find "${TARGET_MODULE}" \( -name ".git" -o -name ".gitmodules" \) | grep -q .; then
  echo "[caas-sync] ERROR: Git metadata was copied into the target module."
  echo "[caas-sync] Remove it before committing:"
  echo "[caas-sync]   rm -rf ${TARGET_MODULE}/.git"
  echo "[caas-sync]   rm -f ${TARGET_MODULE}/.gitmodules"
  exit 1
fi

echo "[caas-sync] CAAS module synced successfully."
echo "[caas-sync] Next steps:"
echo "[caas-sync]   git status"
echo "[caas-sync]   git add -A app/code/Braintly/Caas scripts/sync-caas-module.sh"
echo "[caas-sync]   git commit -m \"Update CAAS module\""
echo "[caas-sync]   git push origin main"
```

Darle permisos de ejecución:

```bash
chmod +x scripts/sync-caas-module.sh
```

### Verificación después de sincronizar

Después de correr el script:

```bash
ls -la app/code/Braintly/Caas/registration.php
ls -la app/code/Braintly/Caas/etc/module.xml
find app/code/Braintly/Caas \( -name ".git" -o -name ".gitmodules" \)
```

El último comando no debe devolver nada.

También se puede verificar un cambio puntual del módulo, por ejemplo:

```bash
grep -R "normalizeStoreUrl" -n app/code/Braintly/Caas/Block/Product/CaasWidget.php
```

### Commit y deploy

```bash
git status
git add -A app/code/Braintly/Caas scripts/sync-caas-module.sh docs/railway-magento-caas-workflow.md
git commit -m "Update CAAS module"
git push origin main
```

Al hacer push a `main`, Railway debería disparar automáticamente un deploy.

---
## Cómo validar que el módulo quedó copiado en el build

El `Dockerfile` incluye una verificación del módulo:

```dockerfile
RUN echo "[caas-build] Verifying Braintly CAAS module..." \
    && ls -la /var/www/html/app/code/Braintly/Caas \
    && test -f /var/www/html/app/code/Braintly/Caas/registration.php \
    && test -f /var/www/html/app/code/Braintly/Caas/etc/module.xml \
    && grep -q "Braintly_Caas" /var/www/html/app/code/Braintly/Caas/etc/module.xml
```

Si falta `registration.php` o `etc/module.xml`, el build falla. Eso es intencional para evitar deployar una imagen con el módulo incompleto.

---

## Cómo funciona el deploy en Railway

Railway está conectado al repo:

```txt
jcampo-b/mangeto2-railway
```

Branch conectada:

```txt
main
```

Cada push a `main` debería disparar un deploy automático.

Si Railway salta un deploy con:

```txt
No changes to watched files
```

revisar:

```txt
Settings → Build → Watch Paths
```

Debe estar vacío.

También revisar:

```txt
Settings → Source → Root Directory
```

Debe estar vacío para que Railway buildee desde la raíz del repo.

---

## Variables requeridas en Railway

El servicio Magento debe tener:

```env
INSTALL_CAAS_MODULE=true
```

Esta variable habilita el bloque del `entrypoint.sh` que sincroniza el módulo desde la imagen Docker hacia el volumen persistente de Magento.

---

## Qué hace el entrypoint con el módulo

Durante el arranque del contenedor, el entrypoint:

1. Verifica que `INSTALL_CAAS_MODULE=true`.
2. Busca el módulo en la imagen:

```txt
/opt/magento/app/code/Braintly/Caas
```

3. Lo copia al volumen persistente de Magento:

```txt
/var/www/html/app/code/Braintly/Caas
```

4. Ejecuta:

```bash
php bin/magento module:enable Braintly_Caas
php bin/magento setup:upgrade
php bin/magento setup:di:compile
php bin/magento setup:static-content:deploy -f
php bin/magento cache:flush
```

5. Guarda un checksum para no repetir el proceso si el módulo no cambió.

---

## Logs esperados en Railway

Cuando el módulo se sincroniza correctamente, los logs deben mostrar algo como:

```txt
[caas] Syncing Braintly CAAS module into Magento volume...
[caas] Enabling Braintly_Caas...
[caas] Running setup:upgrade...
[caas] Compiling dependency injection...
[caas] Deploying static content...
[caas] Flushing cache...
[caas] Braintly_Caas module sync completed successfully.
```

Si aparece:

```txt
Unknown module(s): 'Braintly_Caas'
```

significa que Magento no está detectando el módulo. Revisar que existan:

```txt
app/code/Braintly/Caas/registration.php
app/code/Braintly/Caas/etc/module.xml
```

---

## Cómo verificar desde Magento Admin

Entrar al admin de Magento y revisar:

```txt
Stores → Configuration → Braintly → CAAS - Find My Size
```

Ahí deberían aparecer las opciones de configuración del módulo.

Ejemplo:

```txt
Enable Widget
CAAS API URL
```

Si no aparece:

1. Confirmar que Railway deployó el último commit.
2. Revisar logs `[caas]`.
3. Verificar que el módulo copiado tenga `etc/adminhtml/system.xml`.
4. Forzar un cambio visible en el label del `system.xml` para descartar cache.

---

## Flujo recomendado para pruebas

1. Desarrollar cambios en el módulo original:

```txt
Braintly/CAAS-Magento
```

2. Sincronizar el módulo hacia el fork Railway:

```bash
./scripts/sync-caas-module.sh /absolute/path/to/caas-magento-local/src/app
```

Ejemplo local:

```bash
./scripts/sync-caas-module.sh /Users/awesomejohnny/Development/Braintly/caas-magento-local/src/app
```

3. Verificar archivos clave:

```bash
ls -la app/code/Braintly/Caas/registration.php
ls -la app/code/Braintly/Caas/etc/module.xml
find app/code/Braintly/Caas \( -name ".git" -o -name ".gitmodules" \)
```

El último comando no debe devolver nada.

4. Commit y push:

```bash
git add -A app/code/Braintly/Caas scripts/sync-caas-module.sh docs/railway-magento-caas-workflow.md
git commit -m "Update CAAS module"
git push origin main
```

5. Esperar deploy automático en Railway.
6. Revisar logs `[caas]`.
7. Validar en Magento Admin.
8. Validar en storefront que `window.CAAS_CONFIG` refleje los cambios esperados.

---
## Troubleshooting rápido

### Railway no dispara deploy

Revisar:

```txt
Settings → Source → Branch connected to production = main
Settings → Source → Root Directory = vacío
Settings → Build → Watch Paths = vacío
```

También se puede hacer redeploy manual desde:

```txt
Deployments → Redeploy
```

---

### Build falla en verificación CAAS

Significa que el módulo no está completo dentro del repo Railway.

Revisar:

```bash
ls -la app/code/Braintly/Caas
ls -la app/code/Braintly/Caas/registration.php
ls -la app/code/Braintly/Caas/etc/module.xml
```

Si falta algo, copiar nuevamente el módulo.

---

### Warning de embedded git repository

Si aparece:

```txt
warning: adding embedded git repository: app/code/Braintly/Caas
```

Ejecutar:

```bash
rm -rf app/code/Braintly/Caas/.git
rm -f app/code/Braintly/Caas/.gitmodules
git rm --cached app/code/Braintly/Caas
git add -A app/code/Braintly/Caas
```

---

### Magento no muestra cambios nuevos del módulo

Puede ser cache o checksum.

Opciones:

1. Cambiar algo visible en `etc/adminhtml/system.xml`.
2. Commit + push.
3. Revisar logs `[caas]`.
4. Si no vuelve a sincronizar, cambiar temporalmente el nombre del checksum en `entrypoint.sh`, por ejemplo:

```sh
CAAS_CHECKSUM_FILE="${CAAS_STATE_DIR}/caas-module-v2.checksum"
```

---

## Estado actual esperado

El módulo debería aparecer en Magento Admin bajo:

```txt
Stores → Configuration → Braintly → CAAS - Find My Size
```

Y Railway debería hacer deploy automático cuando se pushea a:

```txt
main
```
