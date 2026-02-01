# plat-auth

A reusable auth platform modeled after Google's sign-up and security flow. Offline-first, works without internet.

## Systems

| System | Description |
|--------|-------------|
| [Authelia](https://github.com/authelia/authelia) | SSO/MFA portal (web GUI, OIDC provider) |
| [Casbin](https://github.com/casbin/casbin) | Per-app RBAC — converts Authelia users/roles to internal permissions |
| [LLDAP](https://github.com/lldap/lldap) | Lightweight LDAP backend |
| [Authelia Admin](https://github.com/asalimonov/authelia-admin) | Admin UI for Authelia |

## Quick Start

Requires [xplat](https://github.com/joeblew999/xplat).

```bash
# Start Authelia (downloads binary automatically)
xplat task authelia:start

# Build from source
xplat task authelia:src:build

# Upload binary to GitHub Releases
xplat task authelia:bin:upload
```

**Local URLs:**
- Authelia: http://127.0.0.1:9091
- API (Swagger UI): http://127.0.0.1:9091/api/
- Login: `admin` / `admin`

## Tasks

```bash
xplat task authelia:debug        # Print all vars
xplat task authelia:src:clone    # Clone Authelia source
xplat task authelia:src:deps     # Install build dependencies
xplat task authelia:src:build    # Build from source
xplat task authelia:bin:upload   # Upload binary to GitHub Releases
xplat task authelia:bin:download # Download binary from GitHub Releases
xplat task authelia:start        # Start Authelia
xplat task authelia:stop         # Stop Authelia
```

## CI

GitHub Actions workflow builds Authelia for multiple platforms via `workflow_dispatch`:

- `linux/amd64`
- `linux/arm64`
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
    Taskfile.yml                # Authelia tasks (build, download, start, stop)
    config.yml                  # Authelia config
    users_database.yml          # Dev user database (admin/admin)
    .env.example                # Secret template
.github/
  workflows/
    ci.yml                      # Multi-platform CI
```
