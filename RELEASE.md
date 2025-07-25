# Release Packaging Guide

YT-MP3 Service Release packaging and distribution guide

## Creating Release Package

### Using Bash Script
```bash
# Create release package
./build.sh --release

# Clean and create release package
./build.sh --clean --release

# View help
./build.sh --help
```


## Release Package Structure

The created release package contains the following structure:

```
yt-mp3-service_YYYYMMDD_HHMMSS/
├── bin/                    # Executable files
│   ├── yt-mp3.exe         # Main server program
│   ├── cert-gen.exe       # SSL certificate generation tool
│   ├── yt-dlp.exe         # YouTube download tool
│   ├── ffmpeg.exe         # Audio processing tool
│   ├── ffplay.exe         # Audio playback tool
│   └── ffprobe.exe        # Audio information tool
├── certs/                 # SSL certificate directory
│   ├── cert.pem          # SSL certificate
│   └── key.pem           # SSL private key
├── downloads/             # Download files directory
├── scripts/               # Management scripts
│   ├── service.sh        # Unified service management script
│   ├── start.sh          # Start script
│   ├── stop.sh           # Stop script
│   ├── status.sh         # Status check script
│   └── build.sh          # Build script
├── docs/                  # Documentation directory
│   ├── BUILD.md          # Build instructions
│   ├── SERVICE.md        # Service management instructions
│   └── Cargo.toml        # Project configuration
├── install.sh             # Installation script
└── PACKAGE_INFO.txt       # Package information file
```

## Distribution Formats

The release package will automatically create the following formats:

- **tar.gz**: `yt-mp3-service_YYYYMMDD_HHMMSS.tar.gz`
- **zip**: `yt-mp3-service_YYYYMMDD_HHMMSS.zip`

## Installation Process

### Method 1: Using Installation Script (Recommended)

```bash
# Extract package
tar -xzf yt-mp3-service_YYYYMMDD_HHMMSS.tar.gz
cd yt-mp3-service_YYYYMMDD_HHMMSS

# Or extract zip package
unzip yt-mp3-service_YYYYMMDD_HHMMSS.zip
cd yt-mp3-service_YYYYMMDD_HHMMSS

# Run installation script
./install.sh
```

### Method 2: Manual Installation

```bash
# Create installation directory
mkdir ~/yt-mp3-service
cd ~/yt-mp3-service

# Copy extracted files
cp -r /path/to/extracted/package/* .

# Set execute permissions (Linux/macOS)
chmod +x bin/*
chmod +x scripts/*.sh

# Create management script link
ln -sf scripts/service.sh service
```

## Using Release Package

### Starting Service
```bash
# Enter installation directory
cd ~/yt-mp3-service

# Start service
./service start

# Or use script directory
./scripts/service.sh start
```

### Managing Service
```bash
# Check status
./service status

# Stop service
./service stop

# Restart service
./service restart

# View logs
./service logs
```

### Accessing Service
- HTTP: http://127.0.0.1:3000
- HTTPS: https://127.0.0.1:3443

## System Requirements

### Minimum Requirements
- **Memory**: 256MB RAM
- **Disk**: 100MB available space
- **Network**: Internet connection (for downloading YouTube content)

### Supported Operating Systems
- Windows 10/11
- Ubuntu 18.04+
- CentOS 7+
- macOS 10.14+
- Other Linux distributions that support Rust

## Custom Configuration

### SSL Certificate
```bash
# Regenerate certificate
./bin/cert-gen.exe

# Or use your own certificate
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
```

### Port Configuration
Default ports:
- HTTP: 3000
- HTTPS: 3443

To modify ports, you need to recompile the source code.

## Troubleshooting

### Installation Issues
```bash
# Check file permissions
ls -la bin/
chmod +x bin/*

# Check dependencies
./bin/yt-mp3.exe --help
```

### Runtime Issues
```bash
# View detailed status
./service status --detailed

# View logs
./service logs --follow

# Check ports
netstat -tulnp | grep -E ":(3000|3443)"
```

### Permission Issues
```bash
# Linux/macOS set permissions
chmod +x bin/*
chmod +x scripts/*.sh

# Check SSL certificate permissions
ls -la certs/
```

## Uninstallation

### Automatic Uninstallation
```bash
# Stop service
./service stop

# Remove installation directory
rm -rf ~/yt-mp3-service
```

### Clean System Services (if configured)
```bash
# systemd (Linux)
sudo systemctl stop yt-mp3
sudo systemctl disable yt-mp3
sudo rm /etc/systemd/system/yt-mp3.service

# launchd (macOS)
sudo launchctl unload /Library/LaunchDaemons/com.yt-mp3.plist
sudo rm /Library/LaunchDaemons/com.yt-mp3.plist
```

## Updates

### Update to New Version
```bash
# Stop current service
./service stop

# Backup configuration (if customized)
cp certs/cert.pem ../backup/
cp certs/key.pem ../backup/

# Install new version
# (follow new version installation steps)

# Restore custom configuration
cp ../backup/cert.pem certs/
cp ../backup/key.pem certs/

# Start new version
./service start
```

## Production Environment Deployment

### System Service Configuration

#### systemd (Linux)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=yt-mp3
WorkingDirectory=/opt/yt-mp3-service
ExecStart=/opt/yt-mp3-service/bin/server
ExecStop=/opt/yt-mp3-service/service stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### Reverse Proxy (nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Security Considerations
1. Use dedicated user to run service
2. Configure firewall rules
3. Use valid SSL certificates
4. Regularly update dependencies
5. Monitor system resources

## Technical Support

If you encounter issues, please:
1. Check documentation in `docs/` directory
2. Check version information in `PACKAGE_INFO.txt`
3. Use `./service status --detailed` to view detailed status
4. View service logs with `./service logs`