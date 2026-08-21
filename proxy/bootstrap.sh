#!/usr/bin/env bash
#
# bootstrap.sh - set up nginx + certbot (Cloudflare DNS-01) inside the proxy LXC
# and issue a wildcard certificate for *.cabral.net.ar.
#
# Run INSIDE the container as root (copy the whole proxy/ dir in first):
#   CLOUDFLARE_DNS_TOKEN=xxxx STAGING=1 bash bootstrap.sh   # staging (testing)
#   CLOUDFLARE_DNS_TOKEN=xxxx bash bootstrap.sh             # production
#
set -euo pipefail

: "${CLOUDFLARE_DNS_TOKEN:?set CLOUDFLARE_DNS_TOKEN to a Cloudflare token with Zone.DNS:Edit}"
EMAIL="${ACME_EMAIL:-ramirocabral04@gmail.com}"
CERT_NAME="cabral-wildcard"
DOMAIN="*.cabral.net.ar"

apt-get update
apt-get install -y nginx certbot python3-certbot-dns-cloudflare

# Cloudflare credentials for the DNS-01 challenge
install -d -m 700 /root/.secrets/certbot
umask 077
cat > /root/.secrets/certbot/cloudflare.ini <<EOF
dns_cloudflare_api_token = ${CLOUDFLARE_DNS_TOKEN}
EOF

STAGING_FLAG=""
[ "${STAGING:-0}" = "1" ] && STAGING_FLAG="--test-cert"

certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  --cert-name "$CERT_NAME" \
  -d "$DOMAIN" \
  --agree-tos -m "$EMAIL" --non-interactive ${STAGING_FLAG}

# Reload nginx automatically after each renewal
install -d /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh <<'EOF'
#!/usr/bin/env bash
systemctl reload nginx
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

# Install the site configs shipped next to this script (skips *.example files)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR"/nginx/*.conf /etc/nginx/conf.d/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx
echo ">> proxy ready. certbot auto-renews via its systemd timer (certbot.timer)."
