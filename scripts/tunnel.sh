#!/bin/bash
# Start cloudflared tunnel → Caddy (forward auth) → Authelia.
# Env vars set by the Taskfile tunnel:run task:
#   CLOUDFLARED, CADDY, AUTH_BINARY, AUTH_CONFIG, AUTH_PORT, AUTH_FLOW, AUTH_FLOWS_DIR, DATA_DIR, CADDY_PORT, CADDYFILE_TEMPLATE
set -e

AUTH_FLOW="${AUTH_FLOW:-2fa}"
FLOW_CONFIG="$AUTH_FLOWS_DIR/$AUTH_FLOW.yml"

if [ ! -f "$FLOW_CONFIG" ]; then
  echo "  ERROR: Unknown flow '$AUTH_FLOW'. Available: $(ls "$AUTH_FLOWS_DIR"/*.yml | xargs -I{} basename {} .yml | tr '\n' ' ')"
  exit 1
fi

LOGFILE="$DATA_DIR/tunnel.log"
rm -f "$LOGFILE"
xplat os mkdir -p "$DATA_DIR" 2>/dev/null || mkdir -p "$DATA_DIR"

# Copy Caddyfile template to data dir
cp "$CADDYFILE_TEMPLATE" "$DATA_DIR/Caddyfile"

# Start cloudflared tunnel connecting to Caddy (plain HTTP).
# Caddy handles forward auth to Authelia's HTTPS endpoint.
$CLOUDFLARED tunnel --url "http://127.0.0.1:$CADDY_PORT" 2>&1 | tee "$LOGFILE" &
CF_PID=$!

# Wait for tunnel URL to appear in log
echo "  Waiting for Cloudflare Tunnel..."
TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$LOGFILE" 2>/dev/null | head -1)
  if [ -n "$TUNNEL_URL" ]; then break; fi
  sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
  echo "  ERROR: Failed to get tunnel URL after 30s"
  kill $CF_PID 2>/dev/null
  exit 1
fi

TUNNEL_DOMAIN=$(echo "$TUNNEL_URL" | sed 's|https://||')

# Generate session config with tunnel domain.
# authelia_url includes /authelia path since Caddy serves portal at that subpath.
cat > "$DATA_DIR/config.session.yml" <<EOF
session:
  secret: insecure_session_secret
  cookies:
    - domain: $TUNNEL_DOMAIN
      authelia_url: $TUNNEL_URL/authelia
      same_site: lax
EOF

echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  CLOUDFLARE TUNNEL READY (via Caddy forward auth)       │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  Public URL:  $TUNNEL_URL"
echo "  Portal:      $TUNNEL_URL/authelia"
echo "  Flow:        $AUTH_FLOW ($FLOW_CONFIG)"
echo ""
echo "  Open the public URL on any device — valid TLS, no warnings."
echo "  Login: admin / admin"
echo ""
echo "  Press Ctrl+C to stop."
echo ""

# Start Caddy
$CADDY run --config "$DATA_DIR/Caddyfile" &
CADDY_PID=$!

# Start Authelia with TLS + flow overlay + session overlay
$AUTH_BINARY \
  --config "$AUTH_CONFIG" \
  --config "$FLOW_CONFIG" \
  --config "$DATA_DIR/config.session.yml" &
AUTH_PID=$!

cleanup() { kill $CF_PID $CADDY_PID $AUTH_PID 2>/dev/null; exit 0; }
trap cleanup INT TERM
wait -n $CF_PID $CADDY_PID $AUTH_PID 2>/dev/null || wait $CF_PID $CADDY_PID $AUTH_PID
