# Service Management Instructions

YT-MP3 Service management script usage guide

## Available Service Management Scripts

### 1. Unified Management Script (Recommended)

#### Bash Version
```bash
# View status and help
scripts/service.sh

# Start service
scripts/service.sh start

# Stop service
scripts/service.sh stop

# Restart service
scripts/service.sh restart

# View detailed status
scripts/service.sh status --detailed

# View logs
scripts/service.sh logs

# Follow logs continuously
scripts/service.sh logs --follow

# Build project
scripts/service.sh build

# Clean temporary files
scripts/service.sh clean
```

#### Windows Batch Version
```cmd
# View status and help
scripts\service.bat

# Start service
scripts\service.bat start

# Stop service
scripts\service.bat stop

# Restart service
scripts\service.bat restart

# View status
scripts\service.bat status

# View logs
scripts\service.bat logs

# Build project
scripts\service.bat build
```

### 2. Individual Function Scripts

#### Start Service
```bash
scripts/start.sh
```

#### Stop Service
```bash
# Basic stop
scripts/stop.sh

# Force stop
scripts/stop.sh --force

# Stop and clean
scripts/stop.sh --clean
```

#### Status Check
```bash
# Basic status
scripts/status.sh

# Detailed status
scripts/status.sh --detailed

# Monitor mode
scripts/status.sh --watch
```

## Service Status Description

### 🟢 Service Running Normal
- Process is running
- Port listening normally
- HTTP/HTTPS responding normally

### 🟡 Service Running but Abnormal
- Process running but port abnormal
- Port normal but response abnormal

### 🔴 Service Not Running
- Process not running
- Port not listening

## Service Ports

- **HTTP**: `http://127.0.0.1:3000`
- **HTTPS**: `https://127.0.0.1:3443`

## Log Files

- **Location**: `server.log`
- **View**: `tail -f server.log` or `scripts/service.sh logs --follow`

## Process Management

### PID File
- **Location**: `server.pid`
- **Contains**: Server process ID

### Process Viewing
```bash
# View service process
ps aux | grep server

# View port occupation
netstat -tulnp | grep -E ":(3000|3443)"
```

## Common Issue Troubleshooting

### 1. Port Occupied
```bash
# Find occupying process
netstat -tulnp | grep :3000
lsof -i :3000

# Terminate occupying process
scripts/service.sh stop --force
```

### 2. Service Startup Failed
```bash
# View detailed status
scripts/service.sh status --detailed

# View logs
scripts/service.sh logs

# Check necessary files
ls -la bin/
ls -la certs/
```

### 3. Certificate Issues
```bash
# Regenerate certificate
rm certs/*
bin/cert-gen.exe

# Or use service script
scripts/service.sh clean
scripts/service.sh build
```

### 4. Permission Issues (Linux/Mac)
```bash
# Grant execute permissions
chmod +x *.sh
chmod +x bin/*
```

## Service Management Best Practices

### 1. Regular Service Status Check
```bash
# Set cron job to check service
crontab -e
# Add: */5 * * * * /path/to/service.sh status > /dev/null || /path/to/service.sh start
```

### 2. Log Rotation
```bash
# Clean logs regularly
if [ -f server.log ] && [ $(stat -f%z server.log) -gt 10485760 ]; then
    mv server.log server.log.old
    scripts/service.sh restart
fi
```

### 3. Monitor Service
```bash
# Monitor mode
scripts/service.sh status --watch
```

### 4. Auto Restart
```bash
# Check and auto restart script
#!/bin/bash
if ! scripts/service.sh status > /dev/null; then
    echo "$(date): Service down, restarting..."
    scripts/service.sh start
fi
```

## Development Mode

### Service Management During Development
```bash
# Quick restart during development
scripts/service.sh restart

# View real-time logs
scripts/service.sh logs --follow

# View detailed status
scripts/service.sh status --detailed
```

### Debug Mode
```bash
# Run in foreground (without script)
bin/yt-mp3.exe

# View detailed logs
RUST_LOG=debug bin/yt-mp3.exe
```

## Production Environment

### System Service (systemd)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/yt-mp3-service
ExecStart=/path/to/yt-mp3-service/bin/server
ExecStop=/path/to/yt-mp3-service/service.sh stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Reverse Proxy (nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Security Considerations

### 1. Firewall Settings
```bash
# Allow local access only
ufw allow from 127.0.0.1 to any port 3000
ufw allow from 127.0.0.1 to any port 3443
```

### 2. SSL Certificate
```bash
# Replace self-signed certificate with valid SSL certificate
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
scripts/service.sh restart
```

### 3. Run User
```bash
# Create dedicated user
sudo useradd -r -s /bin/false yt-mp3
sudo chown -R yt-mp3:yt-mp3 /path/to/yt-mp3-service
```