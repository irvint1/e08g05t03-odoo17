#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SERVICE_NAME="${2:-odoo-compose}"
DOCKER_BIN="${DOCKER_BIN:-$(command -v docker || true)}"
SYSTEMCTL_BIN="${SYSTEMCTL_BIN:-$(command -v systemctl || true)}"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ -z "${DOCKER_BIN}" ]]; then
    echo "Could not find docker in PATH."
    exit 1
fi

if [[ -z "${SYSTEMCTL_BIN}" ]]; then
    echo "Could not find systemctl in PATH."
    exit 1
fi

if [[ ! -d "${REPO_DIR}" ]]; then
    echo "Repository directory does not exist: ${REPO_DIR}"
    exit 1
fi

if [[ ! -f "${REPO_DIR}/docker-compose.yml" ]]; then
    echo "Missing docker-compose.yml in ${REPO_DIR}"
    exit 1
fi

if [[ ! -f "${REPO_DIR}/docker-compose.addons.yml" ]]; then
    echo "Missing docker-compose.addons.yml in ${REPO_DIR}"
    exit 1
fi

TMP_FILE="$(mktemp)"

cat > "${TMP_FILE}" <<EOF
[Unit]
Description=Odoo Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${REPO_DIR}
ExecStart=${DOCKER_BIN} compose -f docker-compose.yml -f docker-compose.addons.yml up -d
ExecStop=${DOCKER_BIN} compose -f docker-compose.yml -f docker-compose.addons.yml stop
RemainAfterExit=yes
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

echo "Installing systemd service to ${SERVICE_PATH}"
sudo cp "${TMP_FILE}" "${SERVICE_PATH}"
rm -f "${TMP_FILE}"

echo "Reloading systemd and enabling ${SERVICE_NAME}.service"
sudo "${SYSTEMCTL_BIN}" daemon-reload
sudo "${SYSTEMCTL_BIN}" enable "${SERVICE_NAME}.service"
sudo "${SYSTEMCTL_BIN}" start "${SERVICE_NAME}.service"

echo ""
echo "Service installed."
echo "Check status with:"
echo "sudo ${SYSTEMCTL_BIN} status ${SERVICE_NAME}.service"
