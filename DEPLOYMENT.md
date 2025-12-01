# MysticCards Deployment Guide

This document covers the online multiplayer server setup for MysticCards using Nakama on Oracle Cloud.

---

## Architecture Overview

```
┌─────────────────┐     HTTPS/WSS      ┌─────────────────────────────────────┐
│  Game Client    │ ◄──────────────────►│  Oracle Cloud VM                    │
│  (Godot/Web)    │     Port 443        │  ┌─────────┐    ┌───────────────┐  │
└─────────────────┘                     │  │  Caddy  │───►│ Nakama :7350  │  │
                                        │  │  :443   │    └───────┬───────┘  │
                                        │  └─────────┘            │          │
                                        │                   ┌─────▼─────┐    │
                                        │                   │ Postgres  │    │
                                        │                   └───────────┘    │
                                        └─────────────────────────────────────┘
```

---

## Server Details

| Item | Value |
|------|-------|
| **Cloud Provider** | Oracle Cloud (Always Free Tier) |
| **Server IP** | `150.136.86.225` |
| **Domain** | `mysticcards.duckdns.org` |
| **Nakama Port** | 7350 (internal), 443 (external via Caddy) |
| **Nakama Console** | https://mysticcards.duckdns.org:7351 |
| **Console Login** | `admin` / `password` |

---

## SSH Access

### From Windows PowerShell:

```powershell
ssh -i C:\Users\avk05\Downloads\ssh-key-2025-11-27.key ubuntu@150.136.86.225
```

### If permission error:
```powershell
icacls "C:\Users\avk05\Downloads\ssh-key-2025-11-27.key" /inheritance:r /grant:r "avk05:(R)"
```

---

## Server Management Commands

### Check running containers:
```bash
docker ps
```

### View Nakama logs:
```bash
cd ~/nakama
docker-compose logs -f nakama
```

### Restart Nakama:
```bash
cd ~/nakama
docker-compose restart
```

### Stop Nakama:
```bash
cd ~/nakama
docker-compose down
```

### Start Nakama:
```bash
cd ~/nakama
docker-compose up -d
```

---

## Caddy (SSL/Reverse Proxy)

### View Caddy status:
```bash
sudo systemctl status caddy
```

### Restart Caddy:
```bash
sudo systemctl restart caddy
```

### View Caddy logs:
```bash
sudo journalctl -u caddy --no-pager -n 50
```

### Edit Caddyfile:
```bash
sudo nano /etc/caddy/Caddyfile
```

### Current Caddyfile:
```
mysticcards.duckdns.org {
    # CORS headers for itch.io and other origins
    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
        Access-Control-Allow-Credentials true
    }
    
    # Handle preflight OPTIONS requests
    @options method OPTIONS
    respond @options 204
    
    # Reverse proxy to Nakama
    reverse_proxy localhost:7350
}
```

---

## Docker Compose Configuration

Located at `~/nakama/docker-compose.yml`:

```yaml
version: '3'
services:
  postgres:
    container_name: nakama_postgres
    image: postgres:12.2-alpine
    environment:
      - POSTGRES_DB=nakama
      - POSTGRES_PASSWORD=localdb
    volumes:
      - data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres", "-d", "nakama"]
      interval: 3s
      timeout: 3s
      retries: 5

  nakama:
    container_name: nakama_server
    image: heroiclabs/nakama:3.21.1
    entrypoint:
      - "/bin/sh"
      - "-ecx"
      - >
        /nakama/nakama migrate up --database.address postgres:localdb@postgres:5432/nakama &&
        exec /nakama/nakama --name mysticcards --database.address postgres:localdb@postgres:5432/nakama --logger.level INFO --session.token_expiry_sec 7200
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "7350:7350"
      - "7351:7351"
    healthcheck:
      test: ["CMD", "/nakama/nakama", "healthcheck"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  data:
```

---

## Game Configuration

### NakamaManager.gd Settings:

```gdscript
var server_key: String = "defaultkey"
var server_host: String = "mysticcards.duckdns.org"
var server_port: int = 443
var server_scheme: String = "https"
var socket_scheme: String = "wss"
```

### For Local Development (Docker Desktop):

```gdscript
var server_key: String = "defaultkey"
var server_host: String = "127.0.0.1"
var server_port: int = 7350
var server_scheme: String = "http"
var socket_scheme: String = "ws"
```

---

## Deploying to itch.io

### 1. Export from Godot:
- Project → Export → Add Preset → Web
- Export Project → Save as `.html`

### 2. Create ZIP:
- Zip all exported files together

### 3. Upload to itch.io:
- Create new project or edit existing
- Upload the ZIP file
- Check "This file will be played in the browser"
- Enable "SharedArrayBuffer support" in Embed options

### 4. Test:
- Play the game on itch.io
- Open browser console (F12) to check for errors

---

## Oracle Cloud Security Rules

### Required Ingress Rules (Networking → VCN → Subnet → Security List):

| Source CIDR | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 0.0.0.0/0 | TCP | 22 | SSH |
| 0.0.0.0/0 | TCP | 80 | HTTP (SSL cert renewal) |
| 0.0.0.0/0 | TCP | 443 | HTTPS |
| 0.0.0.0/0 | TCP | 7350 | Nakama API (optional) |
| 0.0.0.0/0 | TCP | 7351 | Nakama Console (optional) |

### Ubuntu Firewall (iptables):
```bash
sudo iptables -L -n | grep -E "80|443|7350|7351"
```

---

## DuckDNS Configuration

- **Domain**: mysticcards.duckdns.org
- **Points to**: 150.136.86.225
- **Dashboard**: https://www.duckdns.org/

If the server IP changes, update it on DuckDNS.

---

## Troubleshooting

### "Failed to connect to server"
1. Check Nakama is running: `docker ps`
2. Check Caddy is running: `sudo systemctl status caddy`
3. Test healthcheck: https://mysticcards.duckdns.org/healthcheck

### "Username is already in use"
- Fixed in NakamaManager.gd - random usernames are generated
- If still happening, re-export and re-upload the game

### SSL Certificate Issues
- Caddy auto-renews certificates
- Check logs: `sudo journalctl -u caddy -n 100`
- Force renewal: `sudo systemctl restart caddy`

### CORS Errors (Web Build)
- Ensure Caddyfile has CORS headers
- Restart Caddy after changes

### Server Crashed / Out of Memory
```bash
# Check memory
free -h

# Restart everything
cd ~/nakama
docker-compose down
docker-compose up -d
sudo systemctl restart caddy
```

---

## Costs

This setup is **100% free** using:
- Oracle Cloud Always Free Tier (VM.Standard.E2.1.Micro)
- DuckDNS (free dynamic DNS)
- Let's Encrypt (free SSL via Caddy)

---

## Useful Links

- [Nakama Documentation](https://heroiclabs.com/docs/nakama/)
- [Godot Nakama Addon](https://github.com/heroiclabs/nakama-godot)
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [DuckDNS](https://www.duckdns.org/)
- [Caddy Documentation](https://caddyserver.com/docs/)


