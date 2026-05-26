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