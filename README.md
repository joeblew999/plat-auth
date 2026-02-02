# plat-auth

A reusable auth platform modeled after Google's sign-up and security flow. Offline-first, works without internet.

https://github.com/joeblew999/plat-auth

## Systems

| System | Description |
|--------|-------------|
| [Authelia](https://github.com/authelia/authelia) | SSO/MFA portal (web GUI, OIDC provider) |
| [Casbin](https://github.com/casbin/casbin) | Per-app RBAC — converts Authelia users/roles to internal permissions |
| [LLDAP](https://github.com/lldap/lldap) | Lightweight LDAP backend |
| [Authelia Admin](https://github.com/asalimonov/authelia-admin) | Admin UI for Authelia |

## Quick Start

Requires [xplat](https://github.com/joeblew999/xplat) — a single binary that embeds Task runner, process-compose, and cloudflared for tunneling. No separate installs needed.

```bash
# Start Authelia (downloads binary automatically)
xplat task authelia:start

# Build from source
xplat task authelia:src:build

# Upload binary to GitHub Releases
xplat task authelia:bin:upload
```

**Local URLs:**
- Authelia: https://127.0.0.1:9091
- API (Swagger UI): https://127.0.0.1:9091/api/
- Login: `admin` / `admin`

**Mobile / remote testing:** Run `xplat task authelia:tunnel` to get a public `https://xxx.trycloudflare.com` URL via Cloudflare Tunnel — works on any device with no cert install.

**Auth flows:**

```bash
xplat task authelia:tunnel       # 2FA required (default)
xplat task authelia:tunnel:1fa   # Password only (no 2FA)
xplat task authelia:reset        # Fresh start (wipe DB, re-register 2FA)
```

See the [User Guide](docs/user-guide.md) for setup with screenshots.

## Tasks

```bash
xplat task authelia:debug        # Print all vars
xplat task authelia:src:clone    # Clone Authelia source
xplat task authelia:src:deps     # Install build dependencies
xplat task authelia:src:build    # Build from source
xplat task authelia:bin:upload   # Upload binary to GitHub Releases
xplat task authelia:bin:download # Download binary from GitHub Releases
xplat task authelia:start        # Start Authelia locally (2FA by default)
xplat task authelia:stop         # Stop Authelia
xplat task authelia:reset        # Reset data (delete DB + notifications)
xplat task authelia:tunnel       # Cloudflare Tunnel + 2FA (default)
xplat task authelia:tunnel:1fa   # Cloudflare Tunnel + password only
```

## CI

GitHub Actions workflow builds Authelia for multiple platforms via `workflow_dispatch`:

- `linux/amd64`
- `linux/arm64`
- `darwin/amd64`
- `darwin/arm64`
- `windows/amd64`

Uses [xplat setup action](https://github.com/joeblew999/xplat/tree/main/.github/actions/setup) for cross-platform Task execution.

## Architecture

Authelia handles identity (SSO, MFA, OIDC). Each app uses Casbin to map Authelia's `Remote-Groups` header to internal RBAC permissions via a simple policy CSV.

```
Authelia (identity) → Reverse Proxy (headers) → App + Casbin (permissions)
```

## Project Structure

```
Taskfile.yml                    # Root taskfile (shared vars, includes)
systems/
  authelia/
    Taskfile.yml                # Authelia tasks (build, download, start, stop, tunnel)
    config.yml                  # Authelia base config
    flows/
      1fa.yml                   # Flow overlay: password only
      2fa.yml                   # Flow overlay: two-factor (default)
    users_database.yml          # Dev user database (admin/admin)
    .env.example                # Secret template
scripts/
  tunnel.sh                     # Cloudflare tunnel + Authelia orchestration
.github/
  workflows/
    ci.yml                      # Multi-platform CI
```
