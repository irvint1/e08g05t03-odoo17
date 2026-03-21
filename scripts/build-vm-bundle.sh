#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-odoo-erp:18.0-bundle}"
BUNDLE_NAME="${2:-odoo18-vm-bundle}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BUNDLE_DIR="${DIST_DIR}/${BUNDLE_NAME}"
IMAGE_TAR="${BUNDLE_DIR}/odoo18-image.tar"
ARCHIVE_PATH="${DIST_DIR}/${BUNDLE_NAME}.tar.gz"

echo "[1/6] Checking Docker daemon"
docker info >/dev/null

echo "[2/6] Rebuilding bundle folder"
rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}/docker/initdb" "${BUNDLE_DIR}/scripts"

echo "[3/6] Building Odoo 18 image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" -f "${ROOT_DIR}/Dockerfile" "${ROOT_DIR}"

echo "[4/6] Saving image tar"
docker save -o "${IMAGE_TAR}" "${IMAGE_NAME}"

echo "[5/6] Copying runtime files"
cp "${ROOT_DIR}/docker-compose.vm.yml" "${BUNDLE_DIR}/"
cp "${ROOT_DIR}/docker-compose.seed.yml" "${BUNDLE_DIR}/"
cp "${ROOT_DIR}/.env.vm.example" "${BUNDLE_DIR}/"
cp "${ROOT_DIR}/DOCKER_VM_RUN.md" "${BUNDLE_DIR}/"
cp "${ROOT_DIR}/ODOO18_MIGRATION.md" "${BUNDLE_DIR}/"
cp "${ROOT_DIR}/docker/odoo.conf" "${BUNDLE_DIR}/docker/odoo.conf"
cp "${ROOT_DIR}/docker/initdb/00-create-legacy-role.sql" "${BUNDLE_DIR}/docker/initdb/00-create-legacy-role.sql"
cp "${ROOT_DIR}/scripts/start-odoo-vm.sh" "${BUNDLE_DIR}/scripts/start-odoo-vm.sh"

if [[ -f "${ROOT_DIR}/odoo.sql.gz" ]]; then
    cp "${ROOT_DIR}/odoo.sql.gz" "${BUNDLE_DIR}/"
fi

echo "[6/6] Creating tar.gz archive"
rm -f "${ARCHIVE_PATH}"
tar -C "${DIST_DIR}" -czf "${ARCHIVE_PATH}" "${BUNDLE_NAME}"

echo
echo "Bundle ready:"
echo "Folder: ${BUNDLE_DIR}"
echo "Archive: ${ARCHIVE_PATH}"
