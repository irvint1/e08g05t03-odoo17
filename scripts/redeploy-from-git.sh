#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

cd "${REPO_DIR}"

echo "[1/4] Pulling latest changes"
git pull --ff-only

echo "[2/4] Rebuilding and starting containers"
docker compose -f docker-compose.yml -f docker-compose.addons.yml up -d --build

echo "[3/4] Current container status"
docker compose -f docker-compose.yml -f docker-compose.addons.yml ps

echo "[4/4] Useful log command"
echo "docker compose -f docker-compose.yml -f docker-compose.addons.yml logs -f odoo"
