# YT-MP3 Service Development Guide

Comprehensive development documentation for a high-performance YouTube to MP3 service built with Rust and Axum.

## Table of Contents

- [Quick Start](#quick-start)
- [Project Architecture](#project-architecture)
- [Development Environment Setup](#development-environment-setup)
- [Build System](#build-system)
- [Service Management](#service-management)
- [Development Workflow](#development-workflow)
- [Testing and Debugging](#testing-and-debugging)
- [Code Style and Standards](#code-style-and-standards)
- [Deployment Guide](#deployment-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing Guide](#contributing-guide)

## Quick Start

### Development Environment Requirements

- **Rust**: Latest stable version (1.70+)
- **Cargo**: Rust package manager
- **FFmpeg**: Audio processing tool (optional)
- **Network Connection**: For downloading yt-dlp and processing YouTube content

### Quick Setup

```bash
# 1. Clone project
git clone <repository-url>
cd yt-mp3-service

# 2. Check Rust environment
cargo --version
rustc --version

# 3. Build project
./build.sh

# 4. Start service
scripts/service.sh start

# 5. Access service
# HTTP: http://127.0.0.1:3000
# HTTPS: https://127.0.0.1:3443
```

## Project Architecture

### Directory Structure

```
yt-mp3-service/
├── src/                        # Source code
│   ├── main.rs                # Main server application
│   └── bin/                   # Binary tools
│       └── cert-gen.rs        # SSL certificate generation tool
├── bin/                       # Compiled artifacts and tools
│   ├── server(.exe)           # Main server program
│   ├── cert-gen(.exe)         # Certificate generation tool
│   ├── yt-dlp(.exe)          # YouTube download tool
│   └── ffmpeg/               # Audio processing tools
├── certs/                    # SSL certificates
│   ├── cert.pem              # Public key certificate
│   └── key.pem               # Private key
├── downloads/                # Downloaded file storage
├── scripts/                  # Service management scripts
│   ├── service.sh           # Unified service management script
│   ├── start.sh/start.bat   # Start script
│   ├── stop.sh/stop.bat     # Stop script
│   └── status.sh/status.bat # Status check script
├── docs/                     # Documentation directory
│   ├── BUILD.md              # Build instructions
│   ├── SERVICE.md            # Service management instructions
│   └── DEVELOP.md            # Development guide (this file)
├── build.sh                  # Main build script
├── Cargo.toml               # Rust project configuration
└── README.md                # Project description
```

### Core Components

#### 1. Web Server (`src/main.rs`)
- Based on Axum framework
- Supports HTTP/HTTPS dual protocols
- Asynchronous request processing
- Task status management

#### 2. SSL Certificate Generator (`src/bin/cert-gen.rs`)
- Automatically generates self-signed certificates
- Supports RSA and ECDSA algorithms
- Certificate validity management

#### 3. Service Management System
- Cross-platform service control
- Process monitoring and restart
- Log management
- Status checking

### Technology Stack

#### Rust Dependencies

```toml
# Web framework
axum = "0.7"                    # Modern asynchronous Web framework
axum-server = "0.6"             # HTTPS server support

# Asynchronous runtime
tokio = { version = "1.0", features = ["full"] }

# Middleware and tools
tower = "0.4"                   # Service abstraction layer
tower-http = "0.5"              # HTTP middleware

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Other tools
uuid = "1.0"                    # UUID generation
rustls = "0.21"                 # TLS implementation
rcgen = "0.11"                  # Certificate generation
time = "0.3"                    # Time handling
```

#### External Tools

- **yt-dlp**: YouTube content download
- **FFmpeg**: Audio format conversion and processing

## Development Environment Setup

### 1. Rust Toolchain Installation

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload environment
source $HOME/.cargo/env

# Verify installation
cargo --version
rustc --version
```

### 2. Development Tools

```bash
# Code formatting
cargo install rustfmt

# Code checking
cargo install clippy

# Documentation generation
cargo doc --open
```

### 3. Recommended IDE Configuration

#### VS Code
```json
{
  "rust-analyzer.checkOnSave.command": "clippy",
  "rust-analyzer.cargo.buildScripts.enable": true,
  "rust-analyzer.procMacro.enable": true
}
```

#### IntelliJ IDEA
- Install Rust plugin
- Enable Cargo project auto-import

## Build System

### Build Script Overview

The project provides multiple build methods to adapt to different platforms and requirements:

```bash
# Bash script (recommended)
./build.sh

# Windows batch
build.bat

# PowerShell script
./build.ps1
```

### Build Process Details

#### 1. Environment Check
```bash
# Check Rust toolchain
cargo --version >/dev/null 2>&1 || {
    echo "Error: Rust toolchain not found"
    exit 1
}
```

#### 2. Directory Preparation
```bash
# Create necessary directories
mkdir -p bin certs downloads
```

#### 3. Compilation Phase
```bash
# Compile certificate generation tool
cargo build --bin cert-gen --release

# Compile main server
cargo build --bin server --release
```

#### 4. Deployment Phase
```bash
# Copy binary files
cp target/release/cert-gen bin/
cp target/release/server bin/

# Generate SSL certificate (if not exists)
[ ! -f certs/cert.pem ] && bin/cert-gen
```

### Build Options

#### Debug Mode
```bash
# Fast build, includes debug information
cargo build

# Or use script
./build.ps1 -Debug
```

#### Release Mode
```bash
# Optimized build, for production use
cargo build --release

# Default mode
./build.sh
```

#### Clean Build
```bash
# Clean and rebuild
cargo clean
./build.sh --clean
```

## Service Management

### Unified Management Interface

Use the `scripts/service.sh` script for complete service lifecycle management:

```bash
# View help and status
scripts/service.sh

# Start service
scripts/service.sh start

# Stop service
scripts/service.sh stop

# Restart service
scripts/service.sh restart

# View status
scripts/service.sh status

# View logs
scripts/service.sh logs

# Real-time logs
scripts/service.sh logs --follow
```

### Service Status Monitoring

#### Status Indicators
- 🟢 **Running Normal**: Process active, port responding
- 🟡 **Running Abnormal**: Process exists but service abnormal
- 🔴 **Not Running**: Service completely stopped

#### Monitoring Commands
```bash
# Basic status check
scripts/service.sh status

# Detailed status information
scripts/service.sh status --detailed

# Continuous monitoring
scripts/service.sh status --watch
```

### Log Management

#### Log Location
- **Main log**: `server.log`
- **PID file**: `server.pid`

#### Log Viewing
```bash
# View recent logs
tail -f server.log

# Use service script
scripts/service.sh logs --follow
```

## Development Workflow

### 1. Feature Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Develop
# Edit code...

# 3. Test build
./build.sh

# 4. Start testing
scripts/service.sh restart

# 5. Feature testing
# Visit http://127.0.0.1:3000

# 6. Code formatting
cargo fmt

# 7. Code check
cargo clippy

# 8. Commit changes
git add .
git commit -m "feat: add new feature"

# 9. Merge to main branch
git checkout main
git merge feature/new-feature
```

### 2. Hot Reload Development

```bash
# Install cargo-watch (only once)
cargo install cargo-watch

# Auto recompile and restart
cargo watch -x "build --release" -s "scripts/service.sh restart"
```

### 3. Debugging Process

#### Development Debugging
```bash
# Run in foreground to view real-time output
bin/server

# Debug mode
RUST_LOG=debug bin/server
```

#### Production Debugging
```bash
# View detailed status
scripts/service.sh status --detailed

# View logs
scripts/service.sh logs --follow

# Check process
ps aux | grep server
```

## Testing and Debugging

### Unit Testing

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_name

# Detailed test output
cargo test -- --nocapture
```

### Integration Testing

#### API Testing
```bash
# Test basic connection
curl http://127.0.0.1:3000/

# Test download functionality
curl -X POST http://127.0.0.1:3000/download \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "url=https://www.youtube.com/watch?v=VIDEO_ID"

# Test status query
curl http://127.0.0.1:3000/status/TASK_ID
```

#### Performance Testing
```bash
# Use wrk for load testing
wrk -t12 -c400 -d30s --timeout 10s http://127.0.0.1:3000/

# Use ab for benchmark testing
ab -n 1000 -c 10 http://127.0.0.1:3000/
```

### Debugging Tools

#### Memory Analysis
```bash
# Use valgrind (Linux)
valgrind --tool=memcheck ./bin/server

# Use heaptrack (Linux)
heaptrack ./bin/server
```

#### Performance Analysis
```bash
# Use perf (Linux)
perf record ./bin/server
perf report

# Use cargo flamegraph
cargo install flamegraph
cargo flamegraph --bin server
```

## Code Style and Standards

### Formatting Standards

```bash
# Auto format all code
cargo fmt

# Check formatting
cargo fmt -- --check
```

### Code Checking

```bash
# Run Clippy check
cargo clippy

# Strict mode
cargo clippy -- -D warnings
```

### Naming Conventions

#### Files and Directories
- Use `snake_case` for file names
- Directory names use lowercase, separated with hyphens

#### Rust Code
```rust
// Structs use PascalCase
struct TaskStatus;

// Functions and variables use snake_case
fn process_download() {}
let task_id = generate_id();

// Constants use SCREAMING_SNAKE_CASE
const MAX_DOWNLOAD_SIZE: usize = 1024;

// Type aliases use PascalCase
type TaskMap = Arc<Mutex<HashMap<String, TaskStatus>>>;
```

### Documentation Standards

#### Function Documentation
```rust
/// Process YouTube video download request
/// 
/// # Arguments
/// 
/// * `url` - YouTube video URL
/// * `task_id` - Task unique identifier
/// 
/// # Returns
/// 
/// Returns `Result<String, Error>` containing download file path or error information
/// 
/// # Examples
/// 
/// ```
/// let result = process_download("https://youtube.com/watch?v=123", "task-123");
/// ```
fn process_download(url: &str, task_id: &str) -> Result<String, Error> {
    // Implementation...
}
```

## Deployment Guide

### Development Environment Deployment

```bash
# 1. Build project
./build.sh

# 2. Start service
scripts/service.sh start

# 3. Verify deployment
curl http://127.0.0.1:3000/
```

### Production Environment Deployment

#### System Service Configuration

##### systemd (Linux)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=yt-mp3
Group=yt-mp3
WorkingDirectory=/opt/yt-mp3-service
ExecStart=/opt/yt-mp3-service/bin/server
ExecStop=/opt/yt-mp3-service/scripts/service.sh stop
Restart=always
RestartSec=5
StandardOutput=append:/var/log/yt-mp3/access.log
StandardError=append:/var/log/yt-mp3/error.log

[Install]
WantedBy=multi-user.target
```

```bash
# Enable service
sudo systemctl enable yt-mp3
sudo systemctl start yt-mp3
sudo systemctl status yt-mp3
```

##### Windows Service
```bash
# Use NSSM to register Windows service
nssm install "YT-MP3 Service" "C:\path\to\yt-mp3-service\bin\yt-mp3.exe"
nssm set "YT-MP3 Service" AppDirectory "C:\path\to\yt-mp3-service"
nssm start "YT-MP3 Service"
```

#### Reverse Proxy Configuration

##### Nginx
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Support large file upload
        client_max_body_size 100M;
        proxy_request_buffering off;
    }
}
```

##### Apache
```apache
<VirtualHost *:443>
    ServerName your-domain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/
</VirtualHost>
```

### Containerization Deployment

#### Dockerfile
```dockerfile
FROM rust:1.70 as builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/server ./bin/server
COPY --from=builder /app/target/release/cert-gen ./bin/cert-gen

RUN mkdir -p certs downloads

EXPOSE 3000 3443

CMD ["./bin/server"]
```

#### Docker Compose
```yaml
version: '3.8'

services:
  yt-mp3:
    build: .
    ports:
      - "3000:3000"
      - "3443:3443"
    volumes:
      - ./downloads:/app/downloads
      - ./certs:/app/certs
    restart: unless-stopped
    environment:
      - RUST_LOG=info
```

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Issue**: `cargo build` fails
```bash
# Solution
# 1. Update Rust toolchain
rustup update

# 2. Clean and rebuild
cargo clean
cargo build

# 3. Check dependencies
cargo check
```

**Issue**: Linker errors
```bash
# Linux solution
sudo apt-get install build-essential

# macOS solution
xcode-select --install
```

#### 2. Service Startup Issues

**Issue**: Port occupied
```bash
# Find occupying process
netstat -tulnp | grep -E ":(3000|3443)"
lsof -i :3000

# Kill process
scripts/service.sh stop --force
pkill -f server
```

**Issue**: Certificate problems
```bash
# Regenerate certificate
rm certs/*
bin/cert-gen

# Check certificate validity
openssl x509 -in certs/cert.pem -text -noout
```

#### 3. Download Function Issues

**Issue**: yt-dlp missing or outdated
```bash
# Download latest version
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o bin/yt-dlp
chmod +x bin/yt-dlp

# Windows
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o bin/yt-dlp.exe
```

**Issue**: FFmpeg related errors
```bash
# Linux
sudo apt-get install ffmpeg

# macOS
brew install ffmpeg

# Windows - Download FFmpeg and extract to bin/ directory
```

### Debugging Tips

#### Enable Verbose Logging
```bash
# Set log level
export RUST_LOG=debug
./bin/server

# Or run directly
RUST_LOG=trace ./bin/server
```

#### Network Debugging
```bash
# Check service accessibility
curl -v http://127.0.0.1:3000/
curl -k -v https://127.0.0.1:3443/

# Check SSL certificate
openssl s_client -connect 127.0.0.1:3443 -servername localhost
```

#### System Resource Monitoring
```bash
# Monitor process
top -p $(pgrep server)

# Monitor network connections
ss -tulnp | grep server

# Check disk usage
du -sh downloads/
```

## Contributing Guide

### Code Contribution Process

1. **Fork Project**
   ```bash
   git clone https://github.com/your-username/yt-mp3-service.git
   cd yt-mp3-service
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Develop and Test**
   ```bash
   # Develop code
   # Run tests
   cargo test
   
   # Format code
   cargo fmt
   
   # Code check
   cargo clippy
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/amazing-feature
   # Create Pull Request on GitHub
   ```

### Commit Message Standards

Use [Conventional Commits](https://conventionalcommits.org/) format:

```
type(scope): description

body

footer
```

#### Types (type)
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation update
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Test related
- `chore`: Build process or auxiliary tool changes

#### Example
```
feat(api): add thumbnail download endpoint

Add new endpoint /thumbnail/{task_id} to download video thumbnails.
The endpoint supports both JPEG and WebP formats.

Closes #123
```

### Code Review Standards

#### Must Check Items
- [ ] Code conforms to project style standards
- [ ] Contains appropriate error handling
- [ ] Added or updated related tests
- [ ] Updated related documentation
- [ ] Passes all existing tests
- [ ] No security vulnerabilities introduced

#### Recommended Check Items
- [ ] Performance impact assessment
- [ ] Memory usage optimization
- [ ] Appropriate logging
- [ ] Backward compatibility

### Issue Reporting

When submitting issues, please include:

1. **Environment Information**
   - Operating system and version
   - Rust version
   - Project version

2. **Issue Description**
   - Expected behavior
   - Actual behavior
   - Reproduction steps

3. **Related Logs**
   ```bash
   # Collect relevant information
   rustc --version
   cargo --version
   scripts/service.sh status --detailed
   tail -50 server.log
   ```

### Documentation Contribution

#### Documentation Types
- **API Documentation**: Rustdoc comments in code
- **User Guide**: README.md and related .md files
- **Development Documentation**: This file (DEVELOP.md)
- **Build Documentation**: BUILD.md
- **Service Documentation**: SERVICE.md

#### Documentation Standards
- Use clear, concise language
- Provide practical, runnable examples
- Keep updated and accurate
- Support multiple languages (Chinese and English)

---

## Contact and Support

- **Issue Reporting**: Use GitHub Issues
- **Feature Requests**: Use GitHub Discussions
- **Security Issues**: Please email maintainers

Thank you for your contribution to YT-MP3 Service! 🎵