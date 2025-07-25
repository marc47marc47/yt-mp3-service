#!/bin/bash

# YT-MP3 Service Start Script
# 啟動服務腳本

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 函數：打印帶顏色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

# 服務相關變量
SERVER_BINARY="bin/server.exe"
if [ ! -f "$SERVER_BINARY" ]; then
    SERVER_BINARY="bin/server"
fi
PID_FILE="server.pid"
LOG_FILE="server.log"

# 檢查服務是否正在運行
check_service_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 服務正在運行
        else
            rm -f "$PID_FILE"  # 清理無效的PID文件
            return 1  # 服務未運行
        fi
    else
        return 1  # 服務未運行
    fi
}

# 檢查端口是否被佔用
check_ports() {
    local http_port=3000
    local https_port=3443
    
    if netstat -an 2>/dev/null | grep -q ":${http_port}.*LISTEN" || 
       ss -ln 2>/dev/null | grep -q ":${http_port}"; then
        print_warning "端口 ${http_port} 已被佔用"
        return 1
    fi
    
    if netstat -an 2>/dev/null | grep -q ":${https_port}.*LISTEN" || 
       ss -ln 2>/dev/null | grep -q ":${https_port}"; then
        print_warning "端口 ${https_port} 已被佔用"
        return 1
    fi
    
    return 0
}

# 檢查必要文件
check_prerequisites() {
    print_step "檢查運行環境..."
    
    # 檢查服務器可執行文件
    if [ ! -f "$SERVER_BINARY" ]; then
        print_error "找不到服務器可執行文件: $SERVER_BINARY"
        print_info "請先運行構建腳本: ./build.sh"
        exit 1
    fi
    
    # 檢查證書文件
    if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
        print_warning "找不到SSL證書文件"
        print_info "正在生成證書..."
        if [ -f "bin/cert-gen.exe" ]; then
            bin/cert-gen.exe
        elif [ -f "bin/cert-gen" ]; then
            bin/cert-gen
        else
            print_error "找不到證書生成工具"
            exit 1
        fi
    fi
    
    # 檢查yt-dlp
    if [ ! -f "bin/yt-dlp.exe" ] && [ ! -f "bin/yt-dlp" ]; then
        print_warning "找不到 yt-dlp，請確保 yt-dlp 在 bin/ 目錄中"
    fi
    
    print_success "環境檢查完成"
}

# 啟動服務
start_service() {
    print_step "啟動 YT-MP3 服務..."
    
    # 檢查服務是否已經在運行
    if check_service_status; then
        print_warning "服務已經在運行中"
        local pid=$(cat "$PID_FILE")
        print_info "PID: $pid"
        return 0
    fi
    
    # 檢查端口
    if ! check_ports; then
        print_error "端口被佔用，請先關閉佔用端口的程序"
        exit 1
    fi
    
    # 啟動服務器（後台運行）
    print_info "正在啟動服務器..."
    nohup "$SERVER_BINARY" > "$LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # 保存PID
    echo "$server_pid" > "$PID_FILE"
    
    # 等待服務器啟動
    sleep 3
    
    # 驗證服務器是否成功啟動
    if check_service_status; then
        print_success "服務啟動成功！"
        print_info "PID: $server_pid"
        print_info "日志文件: $LOG_FILE"
        echo ""
        print_info "服務地址："
        echo "  🌐 HTTP:  http://127.0.0.1:3000"
        echo "  🔒 HTTPS: https://127.0.0.1:3443"
        echo ""
        print_info "使用以下命令查看日志："
        echo "  tail -f $LOG_FILE"
        echo ""
        print_info "使用以下命令停止服務："
        echo "  ./stop.sh"
    else
        print_error "服務啟動失敗"
        if [ -f "$LOG_FILE" ]; then
            print_info "查看日志以獲取更多信息："
            tail -10 "$LOG_FILE"
        fi
        rm -f "$PID_FILE"
        exit 1
    fi
}

# 主函數
main() {
    echo "========================================="
    echo "🚀 YT-MP3 Service 啟動腳本"
    echo "========================================="
    echo ""
    
    check_prerequisites
    start_service
}

# 錯誤處理
trap 'print_error "啟動過程中出現錯誤"; exit 1' ERR

# 執行主函數
main "$@"