#!/usr/bin/env bash
#
# bootstrap.sh - install Docker and bring up the UniFi stack on the VM.
#
# Runs on a Debian 13 cloud-init VM (see terraform/unifi.tf). Docker is used
# instead of a native apt install because UniFi 10.x needs Java 25 (not in
# Debian) and MongoDB ships no server packages for trixie — the images carry
# their own userland, so none of that matters.
#
# Idempotent: re-running pulls the pinned images and recreates only what
# changed. Existing data in ${STACK_DIR} is left alone; the generated .env is
# never overwritten, so Mongo credentials survive.
set -euo pipefail

STACK_DIR="/opt/unifi"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "!! run as root (sudo bash $0)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---- Docker CE -------------------------------------------------------------
if ! command -v docker > /dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl

  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod 0644 /etc/apt/keyrings/docker.asc

  cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker

# ---- Stack -----------------------------------------------------------------
install -d -m 0755 "${STACK_DIR}"
install -m 0644 "${SRC_DIR}/docker-compose.yaml" "${STACK_DIR}/docker-compose.yaml"
install -m 0755 "${SRC_DIR}/init-mongo.sh" "${STACK_DIR}/init-mongo.sh"

# Credentials are generated here, never committed. Hex only: the linuxserver
# image builds a Mongo connection URI from these, so special characters would
# have to be url-encoded.
if [ ! -f "${STACK_DIR}/.env" ]; then
  umask 077
  cat > "${STACK_DIR}/.env" <<EOF
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=$(openssl rand -hex 24)
MONGO_USER=unifi
MONGO_PASS=$(openssl rand -hex 24)
MONGO_DBNAME=unifi
MONGO_AUTHSOURCE=admin
EOF
  echo ">> generated ${STACK_DIR}/.env"
fi

# /config is owned by PUID/PGID 1000 (the cloud-init user); /data/db by mongo's
# own uid, which the image sets up on first start.
install -d -m 0755 -o 1000 -g 1000 "${STACK_DIR}/config"
install -d -m 0755 "${STACK_DIR}/data/db"

cd "${STACK_DIR}"
docker compose pull
docker compose up -d

IP="$(hostname -I | awk '{print $1}')"
cat <<EOF

>> UniFi stack up. The application takes a minute or two to finish booting.
>>   UI:      https://${IP}:8443   (self-signed cert; the proxy fronts it)
>>   logs:    docker compose -f ${STACK_DIR}/docker-compose.yaml logs -f unifi
>>   status:  docker compose -f ${STACK_DIR}/docker-compose.yaml ps
EOF
