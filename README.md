# YT-MP3 Service

🎵 A fast and reliable YouTube to MP3 conversion service built with Rust and Axum.

## Features

- 🚀 **Fast Conversion**: High-performance YouTube to MP3 conversion using yt-dlp and FFmpeg
- 🖼️ **Thumbnail Support**: Automatically downloads and displays video thumbnails
- 🔒 **HTTPS Support**: Built-in TLS support with automatic certificate generation
- 🌐 **Web Interface**: Clean and intuitive web UI for easy usage
- 📦 **Self-contained**: Complete release packages with all dependencies included
- 🛠️ **Service Management**: Comprehensive scripts for starting, stopping, and monitoring the service

## Quick Start

### Using Release Package (Recommended)

1. **Download the latest release package**
2. **Extract the package**:
   ```bash
   # Linux/macOS
   tar -xzf yt-mp3-service_YYYYMMDD_HHMMSS.tar.gz
   cd yt-mp3-service_YYYYMMDD_HHMMSS
   
   # Windows
   # Extract using Windows Explorer or your preferred tool
   ```

3. **Run the installer**:
   ```bash
   # Linux/macOS
   ./install.sh
   
   # Windows
   install.bat
   ```

4. **Start the service**:
   ```bash
   ./service start
   ```

5. **Access the web interface**:
   - HTTP: http://127.0.0.1:3000
   - HTTPS: https://127.0.0.1:3443

### Building from Source

#### Prerequisites

- [Rust](https://rustup.rs/) (latest stable version)
- Internet connection (to download yt-dlp automatically)
- [FFmpeg](https://ffmpeg.org/) (optional, for advanced audio processing)

**Note**: yt-dlp will be automatically downloaded during the first build.

#### Build Instructions

```bash
# Clone the repository
git clone <repository-url>
cd yt-mp3-service

# Build the project
./build.sh

# Or for a complete release package
./build.sh --release

```

## Usage

### Web Interface

1. Open your browser and navigate to:
   - HTTP: http://127.0.0.1:3000
   - HTTPS: https://127.0.0.1:3443

2. Paste a YouTube URL in the input field
3. Click "開始轉碼" (Start Conversion)
4. Wait for the conversion to complete
5. Download your MP3 file

### Service Management

```bash
# Start the service
./service start

# Stop the service
./service stop

# Check service status
./service status

# Restart the service
./service restart

# View logs
./service logs
```

### Command Line Options

```bash
# Start with custom ports (requires rebuilding)
./bin/server --help

# Generate new SSL certificates
./bin/cert-gen
```

## Configuration

### Default Ports
- **HTTP**: 3000
- **HTTPS**: 3443

### SSL Certificates
The service automatically generates self-signed certificates for HTTPS. For production use, replace the certificates in the `certs/` directory:

```bash
# Generate new certificates
./bin/cert-gen

# Or use your own certificates
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
```

### File Locations
- **Downloads**: `downloads/` directory
- **Certificates**: `certs/` directory
- **Logs**: Console output (can be redirected)

## Development

### Project Structure

```
yt-mp3-service/
├── src/
│   ├── main.rs              # Main server application
│   └── bin/
│       └── cert-gen.rs      # SSL certificate generator
├── bin/                     # Compiled binaries and tools
├── certs/                   # SSL certificates
├── downloads/               # Downloaded files
├── scripts/                 # Service management scripts
├── build.sh                 # Build script (Bash)
├── build.ps1                # Build script (PowerShell)
└── Cargo.toml              # Rust project configuration
```

### Building

```bash
# Development build
cargo build

# Release build
cargo build --release

# Build specific binary
cargo build --bin server --release
cargo build --bin cert-gen --release

# Using build scripts
./build.sh --clean --release
./build.ps1 -Clean -Release
```

### Dependencies

#### Rust Crates
- `axum` - Web framework
- `tokio` - Async runtime
- `axum-server` - HTTPS server support
- `rcgen` - Certificate generation
- `serde` - Serialization
- `tower` - Service abstractions

#### External Tools
- `yt-dlp` - YouTube downloading
- `ffmpeg` - Audio processing (optional)

## API

The service provides a simple REST API:

### Endpoints

- `GET /` - Web interface
- `POST /download` - Start download (form data: `url`)
- `GET /status/{task_id}` - Check task status
- `GET /download/{task_id}` - Download completed file
- `GET /thumbnail/{task_id}` - Get video thumbnail

### Example API Usage

```bash
# Start download
curl -X POST http://127.0.0.1:3000/download \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "url=https://www.youtube.com/watch?v=VIDEO_ID"

# Check status
curl http://127.0.0.1:3000/status/TASK_ID

# Download file
curl -O http://127.0.0.1:3000/download/TASK_ID
```

## Production Deployment

### System Service Setup

#### Linux (systemd)

```bash
# Create service file
sudo tee /etc/systemd/system/yt-mp3.service << EOF
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=yt-mp3
WorkingDirectory=/opt/yt-mp3-service
ExecStart=/opt/yt-mp3-service/bin/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable yt-mp3
sudo systemctl start yt-mp3
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

1. **Run as non-root user**
2. **Configure firewall rules**
3. **Use valid SSL certificates in production**
4. **Monitor system resources**
5. **Regular security updates**

## System Requirements

### Minimum Requirements
- **CPU**: 1 core
- **Memory**: 256MB RAM
- **Storage**: 100MB available space
- **Network**: Internet connection for YouTube downloads

### Supported Operating Systems
- Windows 10/11
- Ubuntu 18.04+
- CentOS 7+
- macOS 10.14+
- Other Linux distributions with Rust support

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Rust installation
cargo --version
rustc --version

# Clean and rebuild
cargo clean
./build.sh --clean
```

#### Service Won't Start
```bash
# Check port availability
netstat -tulnp | grep -E ":(3000|3443)"

# Check permissions
chmod +x bin/*
ls -la bin/

# Check certificates
ls -la certs/
./bin/cert-gen
```

#### Download Failures
```bash
# Check yt-dlp
./bin/yt-dlp --version

# Update yt-dlp
# Download latest version to bin/ directory

# Check internet connection
ping youtube.com
```

### Logs and Debugging

```bash
# Start with verbose output
RUST_LOG=debug ./bin/server

# Check service status
./service status --detailed

# Monitor logs
./service logs --follow
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup

```bash
# Clone and setup
git clone <repository-url>
cd yt-mp3-service

# Install dependencies
cargo check

# Run tests
cargo test

# Format code
cargo fmt

# Lint code
cargo clippy
```

## License

This project is open source. Please check the license file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - YouTube downloading
- [FFmpeg](https://ffmpeg.org/) - Audio processing
- [Axum](https://github.com/tokio-rs/axum) - Web framework
- [Tokio](https://tokio.rs/) - Async runtime

## Support

For issues and questions:

1. Check the documentation in `docs/` directory
2. Review the troubleshooting section above
3. Check existing issues in the repository
4. Create a new issue with detailed information

---

Made with ❤️ and Rust 🦀