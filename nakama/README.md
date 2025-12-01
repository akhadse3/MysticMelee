# Nakama Server Setup for Mystic Cards

This folder contains everything you need to run a local Nakama server for online multiplayer.

## Quick Start (Docker)

1. **Install Docker Desktop** from https://www.docker.com/products/docker-desktop

2. **Start the server:**
   ```bash
   cd nakama
   docker-compose up -d
   ```

3. **Verify it's running:**
   - Open http://localhost:7351 in your browser
   - Login with: admin / password

4. **Stop the server:**
   ```bash
   docker-compose down
   ```

## Server Configuration

The default settings in the game connect to:
- **Host:** 127.0.0.1 (localhost)
- **Port:** 7350
- **Server Key:** defaultkey

### Production Server

For a production server, you should:

1. Deploy Nakama to a cloud provider (AWS, GCP, Azure, DigitalOcean, etc.)
2. Use a proper server key (not "defaultkey")
3. Enable SSL/TLS (use "https" and "wss" schemes)

Update `scripts/NakamaManager.gd` with your server settings:

```gdscript
# Nakama configuration - CHANGE THESE FOR YOUR SERVER
var server_key: String = "your_server_key"
var server_host: String = "your.server.com"
var server_port: int = 7350
var server_scheme: String = "https"  # Use "https" for production
var socket_scheme: String = "wss"    # Use "wss" for production
```

Or call `configure_server()` at runtime:

```gdscript
NakamaManager.configure_server("your.server.com", 7350, "your_key", true)
```

## Nakama Console

When running locally, access the admin console at:
- URL: http://localhost:7351
- Username: admin
- Password: password

From here you can:
- View connected users
- Monitor matches
- View storage data
- Check server logs

## Troubleshooting

### "Connection failed" error
- Make sure Docker is running
- Verify the Nakama container is up: `docker ps`
- Check container logs: `docker logs mystic_cards_nakama`

### "Authentication failed" error
- Ensure the server key matches between client and server
- Default key is "defaultkey" (or "mysticcards_secret" if using our docker-compose)

### Port conflicts
- If port 7350 is in use, change it in docker-compose.yml
- Update `server_port` in NakamaManager.gd to match

## Nakama Documentation

- Official Docs: https://heroiclabs.com/docs/nakama/
- GDScript Client: https://heroiclabs.com/docs/nakama/client-libraries/godot/
- Matchmaking: https://heroiclabs.com/docs/nakama/concepts/multiplayer/matchmaker/




