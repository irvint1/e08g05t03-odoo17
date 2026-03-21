#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${BUNDLE_DIR}/.env.vm"
ENV_TEMPLATE="${BUNDLE_DIR}/.env.vm.example"
COMPOSE_FILE="${BUNDLE_DIR}/docker-compose.vm.yml"
SEED_COMPOSE_FILE="${BUNDLE_DIR}/docker-compose.seed.yml"
IMAGE_TAR="${BUNDLE_DIR}/odoo18-image.tar"
SEED_DUMP="${BUNDLE_DIR}/odoo.sql.gz"

if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required on the VM."
    exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
    cp "${ENV_TEMPLATE}" "${ENV_FILE}"
    echo "Created ${ENV_FILE}. Review the values, then rerun this script."
    exit 1
fi

if [[ -f "${IMAGE_TAR}" ]]; then
    echo "Loading bundled Odoo image from ${IMAGE_TAR}..."
    docker load -i "${IMAGE_TAR}"
else
    echo "No local image tar found. Docker Compose will use the image tag from .env.vm."
fi

echo "Starting Odoo stack..."
compose_args=(--env-file "${ENV_FILE}" -f "${COMPOSE_FILE}")
if [[ -f "${SEED_DUMP}" ]]; then
    echo "Found ${SEED_DUMP}. First-time database bootstrap is enabled."
    compose_args+=(-f "${SEED_COMPOSE_FILE}")
fi
docker compose "${compose_args[@]}" up -d

echo "Odoo is starting. Check logs with:"
echo "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} logs -f"
