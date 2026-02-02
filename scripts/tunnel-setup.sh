#!/bin/bash
# One-shot setup: wait for tunnel URL, generate Authelia session config + Caddyfile.
# Called by process-compose before Caddy and Authelia start.
# Env vars: DATA_DIR, AUTH_FLOW, AUTH_FLOWS_DIR, CADDYFILE_TEMPLATE
set -e

LOGFILE="$DATA_DIR/tunnel.log"
FLOW_CONFIG="$AUTH_FLOWS_DIR/${AUTH_FLOW:-2fa}.yml"

echo "  Waiting for Cloudflare Tunnel URL..."
TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$LOGFILE" 2>/dev/null | head -1)
  if [ -n "$TUNNEL_URL" ]; then break; fi
  sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
  echo "  ERROR: Failed to get tunnel URL after 30s"
  exit 1
fi

TUNNEL_DOMAIN=$(echo "$TUNNEL_URL" | sed 's|https://||')

# Generate tunnel-specific config overlay
cat > "$DATA_DIR/config.session.yml" <<EOF
server:
  address: tcp://0.0.0.0:${AUTH_PORT}/authelia
session:
  secret: insecure_session_secret
  cookies:
    - domain: $TUNNEL_DOMAIN
      authelia_url: $TUNNEL_URL/authelia
      same_site: lax
EOF

# Copy Caddyfile template
cp "$CADDYFILE_TEMPLATE" "$DATA_DIR/Caddyfile"

echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  CLOUDFLARE TUNNEL READY (via Caddy forward auth)       │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  Public URL:  $TUNNEL_URL"
echo "  Portal:      $TUNNEL_URL/authelia"
echo "  Flow:        ${AUTH_FLOW:-2fa} ($FLOW_CONFIG)"
echo ""
echo "  Login: admin / admin"
echo ""
