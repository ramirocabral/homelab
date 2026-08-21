#!/usr/bin/env bash
#
# add-host.sh - reverse-proxy a new service with its OWN Let's Encrypt cert.
#
# Per-host certs (no wildcard): one cert per hostname via Cloudflare DNS-01.
# Adds an nginx vhost from nginx/host.conf.template and reloads. Idempotent:
# re-running for the same FQDN just reissues the cert and rewrites the vhost.
#
# Run INSIDE the proxy LXC as root (after bootstrap.sh):
#   CLOUDFLARE_DNS_TOKEN=xxxx ./add-host.sh truenas.cabral.net.ar https://192.168.9.8
#   CLOUDFLARE_DNS_TOKEN=xxxx STAGING=1 ./add-host.sh ...   # Let's Encrypt staging
#
set -euo pipefail

FQDN="${1:?usage: add-host.sh <fqdn> <upstream-url>   e.g. truenas.cabral.net.ar https://192.168.9.8}"
UPSTREAM="${2:?usage: add-host.sh <fqdn> <upstream-url>   e.g. truenas.cabral.net.ar https://192.168.9.8}"
: "${CLOUDFLARE_DNS_TOKEN:?set CLOUDFLARE_DNS_TOKEN to a Cloudflare token with Zone.DNS:Edit}"
EMAIL="${ACME_EMAIL:-ramirocabral04@gmail.com}"

# Reuse the Cloudflare creds bootstrap.sh already wrote; recreate if missing.
CRED=/root/.secrets/certbot/cloudflare.ini
if [ ! -f "$CRED" ]; then
  install -d -m 700 /root/.secrets/certbot
  umask 077
  printf 'dns_cloudflare_api_token = %s\n' "$CLOUDFLARE_DNS_TOKEN" > "$CRED"
fi

STAGING_FLAG=""
[ "${STAGING:-0}" = "1" ] && STAGING_FLAG="--test-cert"

# One cert, one hostname. cert-name == FQDN keeps the live/ path predictable,
# so the template can hardcode /etc/letsencrypt/live/<FQDN>/.
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CRED" \
  --dns-cloudflare-propagation-seconds 30 \
  --cert-name "$FQDN" \
  -d "$FQDN" \
  --agree-tos -m "$EMAIL" --non-interactive ${STAGING_FLAG}

# Render the vhost from the template (# delimiter: UPSTREAM contains slashes).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="/etc/nginx/conf.d/${FQDN}.conf"
sed -e "s#{{FQDN}}#${FQDN}#g" \
    -e "s#{{UPSTREAM}}#${UPSTREAM}#g" \
    "$SCRIPT_DIR/nginx/host.conf.template" > "$OUT"

nginx -t
systemctl reload nginx
echo ">> ${FQDN} -> ${UPSTREAM} ready (cert: /etc/letsencrypt/live/${FQDN}/, auto-renewed by certbot.timer)."
