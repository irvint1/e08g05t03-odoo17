#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DB_NAME="${2:-odoo}"
SQL_BACKUP="${REPO_DIR}/backup/odoo18/odoo.sql.gz"
FILESTORE_ARCHIVE="${REPO_DIR}/backup/odoo18/filestore-${DB_NAME}.tar.gz"

cd "${REPO_DIR}"

echo "[1/6] Pulling latest changes"
git pull --ff-only

if [[ ! -f "${SQL_BACKUP}" ]]; then
    echo "Missing SQL backup: ${SQL_BACKUP}"
    exit 1
fi

echo "[2/6] Resetting existing Odoo containers and volumes"
docker compose -f docker-compose.yml -f docker-compose.addons.yml down -v --remove-orphans

echo "[3/6] Building and starting Odoo with the repo backup"
docker compose -f docker-compose.yml -f docker-compose.addons.yml -f docker-compose.seed.yml up -d --build

echo "[4/6] Waiting for Odoo container"
for _ in $(seq 1 60); do
    if docker ps --format '{{.Names}}' | grep -qx 'odoo-app'; then
        break
    fi
    sleep 2
done

if ! docker ps --format '{{.Names}}' | grep -qx 'odoo-app'; then
    echo "odoo-app did not start in time."
    exit 1
fi

if [[ -f "${FILESTORE_ARCHIVE}" ]]; then
    echo "[5/6] Restoring filestore archive ${FILESTORE_ARCHIVE}"
    docker exec odoo-app rm -rf "/var/lib/odoo/filestore/${DB_NAME}"
    docker exec odoo-app mkdir -p /var/lib/odoo/filestore
    docker exec -i odoo-app sh -lc "tar -xzf - -C /var/lib/odoo/filestore" < "${FILESTORE_ARCHIVE}"
    docker restart odoo-app >/dev/null
else
    echo "[5/6] No filestore archive found. Skipping attachment restore."
fi

echo "[6/6] Current container status"
docker compose -f docker-compose.yml -f docker-compose.addons.yml ps

echo ""
echo "Odoo is starting. Useful commands:"
echo "docker compose -f docker-compose.yml -f docker-compose.addons.yml logs -f odoo"
echo "Open http://localhost:8069"
