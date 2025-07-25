# Build Instructions

YT-MP3 Service automated build script usage guide

## Available Build Scripts

### 1. Bash Script (Recommended)
```bash
# Basic build
./build.sh

# Grant execute permission (if needed)
chmod +x build.sh && ./build.sh
```

### 2. Windows Batch File
```cmd
build.bat
```

### 3. PowerShell Script
```powershell
# Basic build
.\build.ps1

# Use debug mode
.\build.ps1 -Debug

# Skip certificate generation
.\build.ps1 -NoCert

# Force clean rebuild
.\build.ps1 -Clean
```

## Build Process

The script automatically executes the following steps:

1. **🔍 Environment Check**
   - Verify Rust toolchain (cargo, rustc)
   - Check necessary dependencies

2. **🧹 Clean Build**
   - Clean previous build artifacts

3. **📁 Directory Preparation**
   - Create `bin/`, `certs/`, `downloads/` directories

4. **🔧 Compile Tools**
   - Compile certificate generation tool (`cert-gen`)
   - Deploy to `bin/cert-gen.exe`

5. **🔐 Generate Certificates**
   - Automatically generate SSL self-signed certificates (if not exists)
   - Save to `certs/cert.pem` and `certs/key.pem`

6. **🚀 Compile Server**
   - Compile main server (`server`)
   - Deploy to `bin/yt-mp3.exe`

7. **✅ Verify Deployment**
   - Check if all files are correctly deployed
   - Display build results and usage instructions

## Build Artifacts

After build completion, the `bin/` directory contains:

- `cert-gen.exe` - SSL certificate generation tool
- `yt-mp3.exe` - Main server program
- `yt-dlp.exe` - YouTube download tool (needs manual placement)
- `ffmpeg.exe`, `ffplay.exe`, `ffprobe.exe` - Audio processing tools

## Usage

### Generate New Certificate
```bash
bin/cert-gen.exe
```

### Start Server
```bash
# Direct start
bin/yt-mp3.exe

# Or use service management script
scripts/start.bat
```

### Access Service
- HTTP: http://127.0.0.1:3000
- HTTPS: https://127.0.0.1:3443

## Troubleshooting

### Permission Issues
If encountering permission issues on Linux/Mac:
```bash
chmod +x build.sh
chmod +x bin/*
```

### Rust Toolchain Issues
Ensure Rust is installed:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Certificate Issues
Regenerate certificate:
```bash
rm certs/*
bin/cert-gen.exe
```

### Port Occupation
If port is occupied, terminate existing process:
```bash
# Linux/Mac
pkill -f server

# Windows
taskkill /F /IM yt-mp3.exe
```

## Development Mode

Use debug mode for development:
```powershell
.\build.ps1 -Debug
```

Debug mode features:
- Faster compilation
- Includes debug symbols
- Larger file size
- Lower performance

## Production Deployment

Use release mode for production deployment:
```bash
./build.sh  # Uses release mode by default
```

Release mode features:
- Longer compilation time
- Optimized machine code
- Smaller file size
- Best performance