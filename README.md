# plat-auth

A reusable auth platform modeled after Google's sign-up and security flow. Offline-first, works without internet.

https://github.com/joeblew999/plat-auth

## Systems

| System | Description |
|--------|-------------|
| [Authelia](https://github.com/authelia/authelia) | SSO/MFA portal (web GUI, OIDC provider) |

## Quick Start

Requires [xplat](https://github.com/joeblew999/xplat) — a single binary that embeds Task runner, process-compose, and cloudflared for tunneling. No separate installs needed.

### Local development

```bash
# Download Authelia binary (auto-detects OS/arch)
xplat task authelia:bin:download

# Start Authelia locally with 2FA
xplat task authelia:start
```

- Authelia: https://127.0.0.1:9091
- Swagger UI: https://127.0.0.1:9091/api/
- Login: `admin` / `admin`

### Remote / mobile testing (Cloudflare Tunnel)

Starts Authelia behind a Caddy forward-auth proxy with a public Cloudflare Tunnel URL. Works on any device (iOS, Android, etc.) — no cert install needed.

```bash
# Password only (no 2FA) — easiest for testing
xplat task authelia:tunnel:1fa

# 2FA required (default)
xplat task authelia:tunnel
```

A public `https://xxx.trycloudflare.com` URL will be printed to the console. Open it on any device to test.

### Other commands

```bash
xplat task authelia:reset        # Wipe DB and start fresh
xplat task authelia:stop         # Stop all processes
xplat task authelia:debug        # Print all config vars
```

## Architecture

```
Local:   Browser → Authelia (:9091 HTTPS, self-signed)

Tunnel:  Browser → Cloudflare Tunnel → Caddy (:8080) → Authelia (:9091)
                                          ├─ /authelia/*  → reverse proxy to Authelia
                                          └─ /*           → forward_auth check → protected app
```

Caddy acts as a forward-auth proxy: it checks every request against Authelia's `/api/authz/forward-auth` endpoint server-to-server. The browser never needs to manage auth cookies directly, which fixes Safari/WebKit cookie restrictions on public suffix domains like `trycloudflare.com`.

## Tasks

```bash
xplat task authelia:debug        # Print all vars
xplat task authelia:src:clone    # Clone Authelia source
xplat task authelia:src:deps     # Install build dependencies
xplat task authelia:src:build    # Build from source
xplat task authelia:bin:upload   # Upload binary to GitHub Releases
xplat task authelia:bin:download # Download binary from GitHub Releases
xplat task authelia:caddy:download # Install Caddy (for tunnel mode)
xplat task authelia:start        # Start Authelia locally (2FA by default)
xplat task authelia:stop         # Stop Authelia and Caddy
xplat task authelia:reset        # Reset data (delete DB + notifications)
xplat task authelia:tunnel       # Cloudflare Tunnel + 2FA (default)
xplat task authelia:tunnel:1fa   # Cloudflare Tunnel + password only
```

## Project Structure

```
Taskfile.yml                        # Root taskfile (shared vars, includes)
process-compose.yml                 # Tunnel process orchestration (cloudflared, caddy, authelia)
systems/
  authelia/
    Taskfile.yml                    # Authelia tasks (build, download, start, stop, tunnel)
    config.yml                      # Authelia base config
    Caddyfile.template              # Caddy forward-auth config (used by tunnel mode)
    flows/
      1fa.yml                       # Flow overlay: password only
      2fa.yml                       # Flow overlay: two-factor (default)
    users_database.yml              # Dev user database (admin/admin)
    .env.example                    # Secret template
scripts/
  tunnel-setup.sh                   # Tunnel bootstrap (generates session config + Caddyfile)
.github/
  workflows/
    ci.yml                          # Multi-platform CI
```

## CI

GitHub Actions workflow builds Authelia for multiple platforms via `workflow_dispatch`:

- `linux/amd64`, `linux/arm64`
- `darwin/amd64`, `darwin/arm64`
- `windows/amd64`

Uses [xplat setup action](https://github.com/joeblew999/xplat/tree/main/.github/actions/setup) for cross-platform Task execution.
