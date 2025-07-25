#!/bin/bash

# YT-MP3 Service Stop Script
# 停止服務腳本

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
print_step() { echo -e "${PURPLE}🛑 $1${NC}"; }

# 服務相關變量
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

# 強制終止服務相關進程
force_kill_processes() {
    print_step "查找並終止所有相關進程..."
    
    # 終止server進程
    if command -v pgrep > /dev/null 2>&1; then
        local pids=$(pgrep -f "server" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            print_info "找到server進程: $pids"
            for pid in $pids; do
                kill -TERM "$pid" 2>/dev/null || true
                sleep 1
                if ps -p "$pid" > /dev/null 2>&1; then
                    kill -KILL "$pid" 2>/dev/null || true
                    print_warning "強制終止進程: $pid"
                else
                    print_success "進程已終止: $pid"
                fi
            done
        fi
    fi
    
    # 使用netstat和lsof查找佔用端口的進程
    local ports=(3000 3443)
    for port in "${ports[@]}"; do
        # 嘗試使用不同的方法查找佔用端口的進程
        local pid=""
        
        # 方法1: 使用netstat (Linux)
        if command -v netstat > /dev/null 2>&1; then
            pid=$(netstat -tlnp 2>/dev/null | grep ":${port} " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        fi
        
        # 方法2: 使用ss (現代Linux)
        if [ -z "$pid" ] && command -v ss > /dev/null 2>&1; then
            pid=$(ss -tlnp 2>/dev/null | grep ":${port} " | grep -o 'pid=[0-9]*' | cut -d'=' -f2 | head -1)
        fi
        
        # 方法3: 使用lsof (macOS/Linux)
        if [ -z "$pid" ] && command -v lsof > /dev/null 2>&1; then
            pid=$(lsof -ti ":${port}" 2>/dev/null | head -1)
        fi
        
        if [ -n "$pid" ] && [ "$pid" != "-" ]; then
            print_info "終止佔用端口 ${port} 的進程: $pid"
            kill -TERM "$pid" 2>/dev/null || true
            sleep 1
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -KILL "$pid" 2>/dev/null || true
                print_warning "強制終止佔用端口 ${port} 的進程: $pid"
            fi
        fi
    done
}

# 停止服務
stop_service() {
    print_step "停止 YT-MP3 服務..."
    
    # 檢查服務是否在運行
    if ! check_service_status; then
        print_warning "服務未運行或PID文件不存在"
        # 即使服務未運行，也嘗試清理可能存在的進程
        force_kill_processes
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    print_info "找到服務進程 PID: $pid"
    
    # 嘗試優雅關閉
    print_info "嘗試優雅關閉服務..."
    kill -TERM "$pid" 2>/dev/null || true
    
    # 等待進程結束
    local wait_time=0
    local max_wait=10
    while [ $wait_time -lt $max_wait ]; do
        if ! ps -p "$pid" > /dev/null 2>&1; then
            print_success "服務已優雅關閉"
            rm -f "$PID_FILE"
            return 0
        fi
        sleep 1
        wait_time=$((wait_time + 1))
        echo -n "."
    done
    echo ""
    
    # 強制終止
    print_warning "優雅關閉超時，強制終止進程..."
    kill -KILL "$pid" 2>/dev/null || true
    sleep 1
    
    # 驗證進程是否已終止
    if ps -p "$pid" > /dev/null 2>&1; then
        print_error "無法終止進程 $pid"
        exit 1
    else
        print_success "服務已強制終止"
        rm -f "$PID_FILE"
    fi
    
    # 額外清理其他可能的進程
    force_kill_processes
}

# 清理函數
cleanup() {
    print_step "清理臨時文件..."
    
    # 清理PID文件
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        print_info "已清理 PID 文件"
    fi
    
    # 詢問是否清理日志文件
    if [ -f "$LOG_FILE" ]; then
        echo ""
        read -p "是否清理日志文件 $LOG_FILE? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$LOG_FILE"
            print_info "已清理日志文件"
        else
            print_info "保留日志文件: $LOG_FILE"
        fi
    fi
    
    print_success "清理完成"
}

# 主函數
main() {
    echo "========================================="
    echo "🛑 YT-MP3 Service 停止腳本"
    echo "========================================="
    echo ""
    
    # 解析參數
    local force_mode=false
    local clean_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_mode=true
                shift
                ;;
            -c|--clean)
                clean_mode=true
                shift
                ;;
            -h|--help)
                echo "使用方法: $0 [選項]"
                echo ""
                echo "選項:"
                echo "  -f, --force    強制終止所有相關進程"
                echo "  -c, --clean    停止後清理臨時文件"
                echo "  -h, --help     顯示此幫助信息"
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
    
    if [ "$force_mode" = true ]; then
        print_warning "強制模式：將終止所有相關進程"
        force_kill_processes
    else
        stop_service
    fi
    
    if [ "$clean_mode" = true ]; then
        cleanup
    fi
    
    echo ""
    print_success "服務已停止！"
    
    # 顯示端口狀態
    echo ""
    print_info "檢查端口狀態："
    for port in 3000 3443; do
        if netstat -an 2>/dev/null | grep -q ":${port}.*LISTEN" || 
           ss -ln 2>/dev/null | grep -q ":${port}"; then
            print_warning "端口 ${port} 仍被佔用"
        else
            print_success "端口 ${port} 已釋放"
        fi
    done
}

# 錯誤處理
trap 'print_error "停止過程中出現錯誤"' ERR

# 執行主函數
main "$@"