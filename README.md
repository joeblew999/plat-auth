# plat-auth

Auth platform with SSO, MFA, and OIDC. Built on [Authelia](https://github.com/authelia/authelia).

## Run

Requires [xplat](https://github.com/joeblew999/xplat).

```bash
xplat task authelia:tunnel:1fa
```

Opens a public Cloudflare Tunnel URL. Works on any device — desktop, iOS, Android. Login: `admin` / `admin`

For 2FA mode:

```bash
xplat task authelia:tunnel
```

## Reset

```bash
xplat task authelia:reset
```

## Build from source

```bash
xplat task authelia:src:build
xplat task authelia:bin:upload
```
