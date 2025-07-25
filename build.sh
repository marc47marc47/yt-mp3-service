#!/bin/bash

# YT-MP3 Service Build Script
# Automated compilation and deployment script

set -e  # Exit immediately on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions: Print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Function: Check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed or not in PATH"
        exit 1
    fi
}

# Create release package
create_release_package() {
    print_step "Creating release package..."
    
    local version=$(date +"%Y%m%d_%H%M%S")
    local release_name="yt-mp3-service_${version}"
    local release_dir="release/${release_name}"
    
    # Create release directory structure
    print_info "Creating release directory structure..."
    rm -rf "release"
    mkdir -p "${release_dir}"/{bin,certs,downloads,docs,scripts}
    
    # Copy executable files
    print_info "Copying executable files..."
    cp bin/yt-mp3.exe "${release_dir}/bin/" 2>/dev/null || cp bin/yt-mp3 "${release_dir}/bin/"
    cp bin/cert-gen.exe "${release_dir}/bin/" 2>/dev/null || cp bin/cert-gen "${release_dir}/bin/"
    
    # Copy dependency tools (if exist)
    if [ -f "bin/yt-dlp.exe" ]; then
        cp bin/yt-dlp.exe "${release_dir}/bin/"
    elif [ -f "bin/yt-dlp" ]; then
        cp bin/yt-dlp "${release_dir}/bin/"
    fi
    
    # Copy FFmpeg tools (if exist)
    #for tool in ffmpeg ffplay ffprobe; do
    for tool in ffmpeg ; do
        if [ -f "bin/${tool}.exe" ]; then
            cp "bin/${tool}.exe" "${release_dir}/bin/"
        elif [ -f "bin/${tool}" ]; then
            cp "bin/${tool}" "${release_dir}/bin/"
        fi
    done
    
    # Copy script files
    print_info "Copying management scripts..."
    cp scripts/*.sh "${release_dir}/scripts/" 2>/dev/null || true
    cp scripts/*.bat "${release_dir}/scripts/" 2>/dev/null || true
    
    # Copy documentation
    print_info "Copying documentation..."
    cp *.md "${release_dir}/docs/" 2>/dev/null || true
    cp Cargo.toml "${release_dir}/docs/" 2>/dev/null || true
    
    # Generate SSL certificate
    print_info "Generating SSL certificate..."
    cd "${release_dir}"
    if [ -f "bin/cert-gen.exe" ]; then
        bin/cert-gen.exe
    elif [ -f "bin/cert-gen" ]; then
        bin/cert-gen
    fi
    cd - > /dev/null
    
    # Create installation script
    create_installer "${release_dir}"
    
    # Create package info file
    create_package_info "${release_dir}" "${version}"
    
    # Create compressed package
    print_info "Creating compressed package..."
    cd release
    if command -v tar > /dev/null 2>&1; then
        tar -czf "${release_name}.tar.gz" "${release_name}/"
        print_success "Created: release/${release_name}.tar.gz"
    fi
    
    if command -v zip > /dev/null 2>&1; then
        zip -r "${release_name}.zip" "${release_name}/" > /dev/null
        print_success "Created: release/${release_name}.zip"
    fi
    cd - > /dev/null
    
    print_success "Release package created: ${release_dir}"
    
    # Display release information
    echo ""
    print_info "Release package contents:"
    ls -la "${release_dir}"/
    echo ""
    print_info "Release package size:"
    du -sh "${release_dir}"
    if [ -f "release/${release_name}.tar.gz" ]; then
        ls -lh "release/${release_name}.tar.gz"
    fi
    if [ -f "release/${release_name}.zip" ]; then
        ls -lh "release/${release_name}.zip"
    fi
}

# Create installation script
create_installer() {
    local release_dir="$1"
    
    # Create Linux/Mac installation script
    cat > "${release_dir}/install.sh" << 'EOF'
#!/bin/bash

# YT-MP3 Service Installation Script

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "========================================="
echo "🚀 YT-MP3 Service Installer"
echo "========================================="

# Check if running as root user
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root user is not recommended for this service"
fi

# Select installation directory
DEFAULT_INSTALL_DIR="$HOME/yt-mp3-service"
read -p "Please enter installation directory [default: $DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

print_info "Installation directory: $INSTALL_DIR"

# Create installation directory
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory already exists, will overwrite existing files"
    read -p "Continue installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
fi

mkdir -p "$INSTALL_DIR"

# Copy files
print_info "Copying files..."
cp -r bin "$INSTALL_DIR/"
cp -r certs "$INSTALL_DIR/"
cp -r downloads "$INSTALL_DIR/"
cp -r scripts "$INSTALL_DIR/"
cp -r docs "$INSTALL_DIR/"

# Set execute permissions
print_info "Setting execute permissions..."
chmod +x "$INSTALL_DIR/bin/"*
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Create symbolic links to scripts
print_info "Creating management script links..."
cd "$INSTALL_DIR"

ln -sf "scripts/start.bat" "start.bat"
ln -sf "scripts/stop.bat" "stop.bat"
ln -sf "scripts/status.bat" "status.bat"
cd - > /dev/null

print_success "Installation complete!"
echo ""
print_info "Usage:"
echo "  cd $INSTALL_DIR"
echo "  start.bat     # Start service"
echo "  stop.bat      # Stop service"
echo "  status.bat    # Check status"
echo ""
print_info "Service addresses:"
echo "  🌐 HTTP:  http://127.0.0.1:3000"
echo "  🔒 HTTPS: https://127.0.0.1:3443"
EOF


    # Set installation script permissions
    chmod +x "${release_dir}/install.sh"
    
    print_success "Installation script created"
}

# Create package info file
create_package_info() {
    local release_dir="$1"
    local version="$2"
    
    cat > "${release_dir}/PACKAGE_INFO.txt" << EOF
YT-MP3 Service Release Package
==============================

Version: ${version}
Build time: $(date)
Build platform: $(uname -s) $(uname -m) 2>/dev/null || echo "Windows"

Included components:
- YT-MP3 Service main program
- SSL certificate generation tool
- Service management scripts
- Installation script
- Documentation

System requirements:
- Operating system: Windows/Linux/macOS
- Memory: Minimum 256MB
- Disk space: Minimum 100MB
- Network: Internet connection required to download YouTube content

Installation method:
1. Extract release package
2. Run installation script:
   - Linux/macOS: ./install.sh
   - Windows: install.bat

Usage:
1. Start service: start.bat
2. Visit: http://127.0.0.1:3000
3. Stop service: stop.bat

For more information, please check the documentation in the docs/ directory.
EOF

    print_success "Package info file created"
}

# Main build function
main() {
    echo "========================================="
    echo "🚀 YT-MP3 Service Build Script"
    echo "========================================="
    
    # Parse arguments
    local build_release=false
    local clean_build=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--release)
                build_release=true
                shift
                ;;
            -c|--clean)
                clean_build=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -r, --release    Create release package"
                echo "  -c, --clean      Clean and rebuild"
                echo "  -h, --help       Show this help information"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use $0 --help for help"
                exit 1
                ;;
        esac
    done
    
    # Check necessary tools
    print_step "Checking necessary tools..."
    check_command "cargo"
    check_command "rustc"
    print_success "All necessary tools are ready"
    
    # Clean previous build (if specified)
    if [ "$clean_build" = true ]; then
        print_step "Cleaning previous build..."
        cargo clean
        print_success "Cleanup complete"
    fi
    
    # Create necessary directories
    print_step "Creating necessary directories..."
    mkdir -p bin
    mkdir -p certs
    mkdir -p downloads
    print_success "Directory creation complete"
    
    # Compile certificate generation tool
    print_step "Compiling certificate generation tool..."
    cargo build --bin cert-gen --release
    if [ $? -eq 0 ]; then
        print_success "Certificate generation tool compilation complete"
    else
        print_error "Certificate generation tool compilation failed"
        exit 1
    fi
    
    # Copy certificate generation tool to bin directory
    print_step "Deploying certificate generation tool..."
    cp target/release/cert-gen.exe bin/ 2>/dev/null || cp target/release/cert-gen bin/
    print_success "Certificate generation tool deployed to bin/cert-gen"
    
    # Generate SSL certificate (if not exists)
    if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
        print_step "Generating SSL certificate..."
        bin/cert-gen.exe 2>/dev/null || bin/cert-gen
        print_success "SSL certificate generation complete"
    else
        print_info "SSL certificate already exists, skipping generation"
    fi
    
    # Compile main server
    print_step "Compiling main server..."
    cargo build --bin yt-mp3 --release
    if [ $? -eq 0 ]; then
        print_success "Main server compilation complete"
    else
        print_error "Main server compilation failed"
        exit 1
    fi
    
    # Copy server to bin directory
    print_step "Deploying server..."
    cp target/release/yt-mp3.exe bin/ 2>/dev/null || cp target/release/yt-mp3 bin/
    print_success "Server deployed to bin/yt-mp3"
    
    # Check and download yt-dlp
    if [ ! -f "bin/yt-dlp.exe" ] && [ ! -f "bin/yt-dlp" ]; then
        print_step "Downloading yt-dlp..."
        
        # Check if curl or wget is available
        if command -v curl >/dev/null 2>&1; then
            curl -L "https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe" -o "bin/yt-dlp.exe"
        elif command -v wget >/dev/null 2>&1; then
            wget "https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe" -O "bin/yt-dlp.exe"
        else
            print_error "Need curl or wget to download yt-dlp"
            print_warning "Please manually download yt-dlp.exe to bin/ directory"
            print_info "Download URL: https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe"
        fi
        
        if [ -f "bin/yt-dlp.exe" ]; then
            chmod +x "bin/yt-dlp.exe"
            print_success "yt-dlp download complete"
        else
            print_warning "yt-dlp download failed, please manually download to bin/ directory"
        fi
    else
        print_success "yt-dlp is ready"
    fi
    
    # Check and download FFmpeg
    if [ ! -f "bin/ffmpeg.exe" ] && [ ! -f "bin/ffmpeg" ]; then
        print_step "Downloading FFmpeg..."
        
        local ffmpeg_url="https://github.com/GyanD/codexffmpeg/releases/download/7.1.1/ffmpeg-7.1.1-essentials_build.zip"
        local ffmpeg_zip="tmp/ffmpeg.zip"
        local ffmpeg_extract_dir="tmp/ffmpeg_extract"
        
        # Create temporary directory
        mkdir -p tmp
        
        # Download FFmpeg
        if command -v curl >/dev/null 2>&1; then
            curl -L "$ffmpeg_url" -o "$ffmpeg_zip"
        elif command -v wget >/dev/null 2>&1; then
            wget "$ffmpeg_url" -O "$ffmpeg_zip"
        else
            print_error "Need curl or wget to download FFmpeg"
            print_warning "Please manually download FFmpeg to bin/ directory"
            print_info "Download URL: $ffmpeg_url"
        fi
        
        if [ -f "$ffmpeg_zip" ]; then
            print_step "Extracting FFmpeg..."
            
            # Check extraction tools
            if command -v unzip >/dev/null 2>&1; then
                # Create extraction directory
                rm -rf "$ffmpeg_extract_dir"
                mkdir -p "$ffmpeg_extract_dir"
                
                # Extract
                unzip -q "$ffmpeg_zip" -d "$ffmpeg_extract_dir"
                
                # Find and copy exe files to bin directory
                print_step "Copying FFmpeg executable files..."
                find "$ffmpeg_extract_dir" -name "*.exe" -type f | while read exe_file; do
                    filename=$(basename "$exe_file")
                    cp "$exe_file" "bin/$filename"
                    chmod +x "bin/$filename"
                    print_info "Copied: $filename"
                done
                
                # Clean up temporary files
                rm -rf "$ffmpeg_extract_dir"
                rm -f "$ffmpeg_zip"
                
                # Verify FFmpeg tools
                if [ -f "bin/ffmpeg.exe" ]; then
                    print_success "FFmpeg download and installation complete"
                else
                    print_warning "FFmpeg exe files not found, please check the downloaded archive"
                fi
            else
                print_error "Need unzip command to extract FFmpeg"
                print_warning "Please manually extract $ffmpeg_zip and copy *.exe files to bin/ directory"
            fi
        else
            print_warning "FFmpeg download failed, please manually download to bin/ directory"
        fi
    else
        print_success "FFmpeg is ready"
    fi
    
    # Display build results
    echo ""
    echo "========================================="
    echo "🎉 Build complete!"
    echo "========================================="
    echo ""
    
    # If release mode is specified, create release package
    if [ "$build_release" = true ]; then
        echo ""
        create_release_package
    else
        print_info "Compiled files:"
        ls -la bin/ | grep -E "\.(exe|sh)$|^[^.]*$" | grep -v "^d"
        echo ""
        print_info "Certificate files:"
        ls -la certs/
        echo ""
        echo "📋 Usage instructions:"
        echo "  🔧 Regenerate certificate: bin/cert-gen"
        echo "  🚀 Start server:   bin/yt-mp3"
        echo "  🌐 HTTP:         http://127.0.0.1:3000"
        echo "  🔒 HTTPS:        https://127.0.0.1:3443"
        echo ""
        echo "💡 Tip: Use $0 --release to create complete release package"
        echo ""
    fi
}

# Error handling
trap 'print_error "Error occurred during build process"; exit 1' ERR

# Execute main function
main "$@"