#!/bin/bash

# YT-MP3 Service Build Script
# 自動化編譯和部署腳本

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：打印帶顏色的消息
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

# 函數：檢查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安裝或不在PATH中"
        exit 1
    fi
}

# 創建release包
create_release_package() {
    print_step "創建release包..."
    
    local version=$(date +"%Y%m%d_%H%M%S")
    local release_name="yt-mp3-service_${version}"
    local release_dir="release/${release_name}"
    
    # 創建release目錄結構
    print_info "創建release目錄結構..."
    rm -rf "release"
    mkdir -p "${release_dir}"/{bin,certs,downloads,docs,scripts}
    
    # 複製可執行文件
    print_info "複製可執行文件..."
    cp bin/server.exe "${release_dir}/bin/" 2>/dev/null || cp bin/server "${release_dir}/bin/"
    cp bin/cert-gen.exe "${release_dir}/bin/" 2>/dev/null || cp bin/cert-gen "${release_dir}/bin/"
    
    # 複製依賴工具（如果存在）
    if [ -f "bin/yt-dlp.exe" ]; then
        cp bin/yt-dlp.exe "${release_dir}/bin/"
    elif [ -f "bin/yt-dlp" ]; then
        cp bin/yt-dlp "${release_dir}/bin/"
    fi
    
    # 複製FFmpeg工具（如果存在）
    for tool in ffmpeg ffplay ffprobe; do
        if [ -f "bin/${tool}.exe" ]; then
            cp "bin/${tool}.exe" "${release_dir}/bin/"
        elif [ -f "bin/${tool}" ]; then
            cp "bin/${tool}" "${release_dir}/bin/"
        fi
    done
    
    # 複製腳本文件
    print_info "複製管理腳本..."
    cp scripts/*.sh "${release_dir}/scripts/" 2>/dev/null || true
    cp scripts/*.bat "${release_dir}/scripts/" 2>/dev/null || true
    
    # 複製文檔
    print_info "複製文檔..."
    cp *.md "${release_dir}/docs/" 2>/dev/null || true
    cp Cargo.toml "${release_dir}/docs/" 2>/dev/null || true
    
    # 生成SSL證書
    print_info "生成SSL證書..."
    cd "${release_dir}"
    if [ -f "bin/cert-gen.exe" ]; then
        bin/cert-gen.exe
    elif [ -f "bin/cert-gen" ]; then
        bin/cert-gen
    fi
    cd - > /dev/null
    
    # 創建安裝腳本
    create_installer "${release_dir}"
    
    # 創建package信息文件
    create_package_info "${release_dir}" "${version}"
    
    # 創建壓縮包
    print_info "創建壓縮包..."
    cd release
    if command -v tar > /dev/null 2>&1; then
        tar -czf "${release_name}.tar.gz" "${release_name}/"
        print_success "已創建: release/${release_name}.tar.gz"
    fi
    
    if command -v zip > /dev/null 2>&1; then
        zip -r "${release_name}.zip" "${release_name}/" > /dev/null
        print_success "已創建: release/${release_name}.zip"
    fi
    cd - > /dev/null
    
    print_success "Release包創建完成: ${release_dir}"
    
    # 顯示release信息
    echo ""
    print_info "Release包內容:"
    ls -la "${release_dir}"/
    echo ""
    print_info "Release包大小:"
    du -sh "${release_dir}"
    if [ -f "release/${release_name}.tar.gz" ]; then
        ls -lh "release/${release_name}.tar.gz"
    fi
    if [ -f "release/${release_name}.zip" ]; then
        ls -lh "release/${release_name}.zip"
    fi
}

# 創建安裝腳本
create_installer() {
    local release_dir="$1"
    
    # 創建Linux/Mac安裝腳本
    cat > "${release_dir}/install.sh" << 'EOF'
#!/bin/bash

# YT-MP3 Service 安裝腳本

set -e

# 顏色定義
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
echo "🚀 YT-MP3 Service 安裝程序"
echo "========================================="

# 檢查是否為root用戶
if [ "$EUID" -eq 0 ]; then
    print_warning "不建議以root用戶運行此服務"
fi

# 選擇安裝目錄
DEFAULT_INSTALL_DIR="$HOME/yt-mp3-service"
read -p "請輸入安裝目錄 [默認: $DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

print_info "安裝目錄: $INSTALL_DIR"

# 創建安裝目錄
if [ -d "$INSTALL_DIR" ]; then
    print_warning "目錄已存在，將覆蓋現有文件"
    read -p "繼續安裝? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "安裝已取消"
        exit 0
    fi
fi

mkdir -p "$INSTALL_DIR"

# 複製文件
print_info "複製文件..."
cp -r bin "$INSTALL_DIR/"
cp -r certs "$INSTALL_DIR/"
cp -r downloads "$INSTALL_DIR/"
cp -r scripts "$INSTALL_DIR/"
cp -r docs "$INSTALL_DIR/"

# 設置執行權限
print_info "設置執行權限..."
chmod +x "$INSTALL_DIR/bin/"*
chmod +x "$INSTALL_DIR/scripts/"*.sh

# 創建符號鏈接到腳本
print_info "創建管理腳本鏈接..."
cd "$INSTALL_DIR"

ln -sf "scripts/start.bat" "start.bat"
ln -sf "scripts/stop.bat" "stop.bat"
ln -sf "scripts/status.bat" "status.bat"
cd - > /dev/null

print_success "安裝完成！"
echo ""
print_info "使用方法："
echo "  cd $INSTALL_DIR"
echo "  start.bat     # 啟動服務"
echo "  stop.bat      # 停止服務"
echo "  status.bat    # 查看狀態"
echo ""
print_info "服務地址："
echo "  🌐 HTTP:  http://127.0.0.1:3000"
echo "  🔒 HTTPS: https://127.0.0.1:3443"
EOF


    # 設置安裝腳本權限
    chmod +x "${release_dir}/install.sh"
    
    print_success "安裝腳本已創建"
}

# 創建package信息文件
create_package_info() {
    local release_dir="$1"
    local version="$2"
    
    cat > "${release_dir}/PACKAGE_INFO.txt" << EOF
YT-MP3 Service Release Package
==============================

版本: ${version}
構建時間: $(date)
構建平台: $(uname -s) $(uname -m) 2>/dev/null || echo "Windows"

包含組件:
- YT-MP3 Service 主程序
- SSL證書生成工具
- 服務管理腳本
- 安裝腳本
- 文檔

系統要求:
- 操作系統: Windows/Linux/macOS
- 內存: 最少 256MB
- 磁盤空間: 最少 100MB
- 網絡: 需要互聯網連接下載YouTube內容

安裝方法:
1. 解壓release包
2. 運行安裝腳本:
   - Linux/macOS: ./install.sh
   - Windows: install.bat

使用方法:
1. 啟動服務: start.bat
2. 訪問: http://127.0.0.1:3000
3. 停止服務: stop.bat

更多信息請查看 docs/ 目錄中的文檔。
EOF

    print_success "Package信息文件已創建"
}

# 主要構建函數
main() {
    echo "========================================="
    echo "🚀 YT-MP3 Service 構建腳本"
    echo "========================================="
    
    # 解析參數
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
                echo "使用方法: $0 [選項]"
                echo ""
                echo "選項:"
                echo "  -r, --release    創建release包"
                echo "  -c, --clean      清理後重新構建"
                echo "  -h, --help       顯示此幫助信息"
                echo ""
                exit 0
                ;;
            *)
                print_error "未知選項: $1"
                echo "使用 $0 --help 查看幫助"
                exit 1
                ;;
        esac
    done
    
    # 檢查必要的工具
    print_step "檢查必要工具..."
    check_command "cargo"
    check_command "rustc"
    print_success "所有必要工具已就緒"
    
    # 清理之前的構建（如果指定）
    if [ "$clean_build" = true ]; then
        print_step "清理之前的構建..."
        cargo clean
        print_success "清理完成"
    fi
    
    # 創建必要的目錄
    print_step "創建必要目錄..."
    mkdir -p bin
    mkdir -p certs
    mkdir -p downloads
    print_success "目錄創建完成"
    
    # 編譯證書生成工具
    print_step "編譯證書生成工具..."
    cargo build --bin cert-gen --release
    if [ $? -eq 0 ]; then
        print_success "證書生成工具編譯完成"
    else
        print_error "證書生成工具編譯失敗"
        exit 1
    fi
    
    # 複製證書生成工具到bin目錄
    print_step "部署證書生成工具..."
    cp target/release/cert-gen.exe bin/ 2>/dev/null || cp target/release/cert-gen bin/
    print_success "證書生成工具已部署到 bin/cert-gen"
    
    # 生成SSL證書（如果不存在）
    if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
        print_step "生成SSL證書..."
        bin/cert-gen.exe 2>/dev/null || bin/cert-gen
        print_success "SSL證書生成完成"
    else
        print_info "SSL證書已存在，跳過生成"
    fi
    
    # 編譯主服務器
    print_step "編譯主服務器..."
    cargo build --bin server --release
    if [ $? -eq 0 ]; then
        print_success "主服務器編譯完成"
    else
        print_error "主服務器編譯失敗"
        exit 1
    fi
    
    # 複製服務器到bin目錄
    print_step "部署服務器..."
    cp target/release/server.exe bin/ 2>/dev/null || cp target/release/server bin/
    print_success "服務器已部署到 bin/server"
    
    # 檢查並下載yt-dlp
    if [ ! -f "bin/yt-dlp.exe" ] && [ ! -f "bin/yt-dlp" ]; then
        print_step "下載 yt-dlp..."
        
        # 檢查是否有 curl 或 wget
        if command -v curl >/dev/null 2>&1; then
            curl -L "https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe" -o "bin/yt-dlp.exe"
        elif command -v wget >/dev/null 2>&1; then
            wget "https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe" -O "bin/yt-dlp.exe"
        else
            print_error "需要 curl 或 wget 來下載 yt-dlp"
            print_warning "請手動下載 yt-dlp.exe 到 bin/ 目錄"
            print_info "下載地址: https://github.com/yt-dlp/yt-dlp/releases/download/2025.07.21/yt-dlp.exe"
        fi
        
        if [ -f "bin/yt-dlp.exe" ]; then
            chmod +x "bin/yt-dlp.exe"
            print_success "yt-dlp 下載完成"
        else
            print_warning "yt-dlp 下載失敗，請手動下載到 bin/ 目錄"
        fi
    else
        print_success "yt-dlp 已就緒"
    fi
    
    # 檢查並下載FFmpeg
    if [ ! -f "bin/ffmpeg.exe" ] && [ ! -f "bin/ffmpeg" ]; then
        print_step "下載 FFmpeg..."
        
        local ffmpeg_url="https://github.com/GyanD/codexffmpeg/releases/download/7.1.1/ffmpeg-7.1.1-essentials_build.zip"
        local ffmpeg_zip="tmp/ffmpeg.zip"
        local ffmpeg_extract_dir="tmp/ffmpeg_extract"
        
        # 創建臨時目錄
        mkdir -p tmp
        
        # 下載FFmpeg
        if command -v curl >/dev/null 2>&1; then
            curl -L "$ffmpeg_url" -o "$ffmpeg_zip"
        elif command -v wget >/dev/null 2>&1; then
            wget "$ffmpeg_url" -O "$ffmpeg_zip"
        else
            print_error "需要 curl 或 wget 來下載 FFmpeg"
            print_warning "請手動下載 FFmpeg 到 bin/ 目錄"
            print_info "下載地址: $ffmpeg_url"
        fi
        
        if [ -f "$ffmpeg_zip" ]; then
            print_step "解壓縮 FFmpeg..."
            
            # 檢查解壓工具
            if command -v unzip >/dev/null 2>&1; then
                # 創建解壓目錄
                rm -rf "$ffmpeg_extract_dir"
                mkdir -p "$ffmpeg_extract_dir"
                
                # 解壓縮
                unzip -q "$ffmpeg_zip" -d "$ffmpeg_extract_dir"
                
                # 查找並複製exe文件到bin目錄
                print_step "複製 FFmpeg 執行文件..."
                find "$ffmpeg_extract_dir" -name "*.exe" -type f | while read exe_file; do
                    filename=$(basename "$exe_file")
                    cp "$exe_file" "bin/$filename"
                    chmod +x "bin/$filename"
                    print_info "已複製: $filename"
                done
                
                # 清理臨時文件
                rm -rf "$ffmpeg_extract_dir"
                rm -f "$ffmpeg_zip"
                
                # 驗證FFmpeg工具
                if [ -f "bin/ffmpeg.exe" ]; then
                    print_success "FFmpeg 下載和安裝完成"
                else
                    print_warning "FFmpeg exe 文件未找到，請檢查下載的壓縮包"
                fi
            else
                print_error "需要 unzip 命令來解壓縮 FFmpeg"
                print_warning "請手動解壓縮 $ffmpeg_zip 並將 *.exe 文件複製到 bin/ 目錄"
            fi
        else
            print_warning "FFmpeg 下載失敗，請手動下載到 bin/ 目錄"
        fi
    else
        print_success "FFmpeg 已就緒"
    fi
    
    # 顯示構建結果
    echo ""
    echo "========================================="
    echo "🎉 構建完成！"
    echo "========================================="
    echo ""
    
    # 如果指定了release模式，創建release包
    if [ "$build_release" = true ]; then
        echo ""
        create_release_package
    else
        print_info "編譯的文件："
        ls -la bin/ | grep -E "\.(exe|sh)$|^[^.]*$" | grep -v "^d"
        echo ""
        print_info "證書文件："
        ls -la certs/
        echo ""
        echo "📋 使用說明："
        echo "  🔧 重新生成證書: bin/cert-gen"
        echo "  🚀 啟動服務器:   bin/server"
        echo "  🌐 HTTP:         http://127.0.0.1:3000"
        echo "  🔒 HTTPS:        https://127.0.0.1:3443"
        echo ""
        echo "💡 提示: 使用 $0 --release 創建完整的release包"
        echo ""
    fi
}

# 錯誤處理
trap 'print_error "構建過程中出現錯誤"; exit 1' ERR

# 執行主函數
main "$@"
