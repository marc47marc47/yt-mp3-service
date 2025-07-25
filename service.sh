#!/bin/bash

# YT-MP3 Service Management Script
# 統一服務管理腳本

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 函數：打印帶顏色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_step() { echo -e "${PURPLE}🔄 $1${NC}"; }
print_title() { echo -e "${BOLD}${CYAN}$1${NC}"; }

# 顯示橫幅
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    YT-MP3 Service Manager                   ║"
    echo "║                     服務管理工具                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 顯示幫助信息
show_help() {
    show_banner
    echo ""
    echo -e "${BOLD}使用方法:${NC} $0 [命令] [選項]"
    echo ""
    echo -e "${BOLD}可用命令:${NC}"
    echo "  start                啟動服務"
    echo "  stop                 停止服務"
    echo "  restart              重啟服務"
    echo "  status               查看服務狀態"
    echo "  logs                 查看服務日志"
    echo "  build                構建項目"
    echo "  clean                清理臨時文件"
    echo "  install              安裝依賴"
    echo ""
    echo -e "${BOLD}狀態命令選項:${NC}"
    echo "  status -d, --detailed     顯示詳細狀態"
    echo "  status -w, --watch        監控模式"
    echo ""
    echo -e "${BOLD}停止命令選項:${NC}"
    echo "  stop -f, --force          強制停止"
    echo "  stop -c, --clean          停止後清理"
    echo ""
    echo -e "${BOLD}日志命令選項:${NC}"
    echo "  logs -f, --follow         持續查看日志"
    echo "  logs -n <NUM>             顯示最後N行"
    echo ""
    echo -e "${BOLD}示例:${NC}"
    echo "  $0 start                  # 啟動服務"
    echo "  $0 stop --force           # 強制停止服務"
    echo "  $0 status --detailed      # 顯示詳細狀態"
    echo "  $0 logs --follow          # 持續查看日志"
    echo "  $0 restart                # 重啟服務"
    echo ""
}

# 快速狀態檢查
quick_status_check() {
    local PID_FILE="server.pid"
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 運行中
        fi
    fi
    return 1  # 未運行
}

# 執行啟動
cmd_start() {
    print_title "🚀 啟動 YT-MP3 服務"
    echo ""
    
    if quick_status_check; then
        print_warning "服務已在運行中"
        echo ""
        print_info "使用以下命令查看狀態："
        echo "  $0 status"
        return 0
    fi
    
    if [ -f "start.sh" ]; then
        chmod +x start.sh
        ./start.sh
    else
        print_error "找不到啟動腳本 start.sh"
        exit 1
    fi
}

# 執行停止
cmd_stop() {
    local stop_args=()
    
    # 解析停止參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                stop_args+=("--force")
                shift
                ;;
            -c|--clean)
                stop_args+=("--clean")
                shift
                ;;
            *)
                print_error "未知選項: $1"
                echo "使用 $0 help 查看幫助"
                exit 1
                ;;
        esac
    done
    
    print_title "🛑 停止 YT-MP3 服務"
    echo ""
    
    if ! quick_status_check; then
        print_warning "服務未運行"
        return 0
    fi
    
    if [ -f "stop.sh" ]; then
        chmod +x stop.sh
        ./stop.sh "${stop_args[@]}"
    else
        print_error "找不到停止腳本 stop.sh"
        exit 1
    fi
}

# 執行重啟
cmd_restart() {
    print_title "🔄 重啟 YT-MP3 服務"
    echo ""
    
    print_step "正在停止服務..."
    cmd_stop
    
    echo ""
    print_step "等待服務完全停止..."
    sleep 2
    
    echo ""
    print_step "正在啟動服務..."
    cmd_start
}

# 執行狀態檢查
cmd_status() {
    local status_args=()
    
    # 解析狀態參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--detailed)
                status_args+=("--detailed")
                shift
                ;;
            -w|--watch)
                status_args+=("--watch")
                shift
                ;;
            *)
                print_error "未知選項: $1"
                echo "使用 $0 help 查看幫助"
                exit 1
                ;;
        esac
    done
    
    if [ -f "status.sh" ]; then
        chmod +x status.sh
        ./status.sh "${status_args[@]}"
    else
        print_error "找不到狀態腳本 status.sh"
        exit 1
    fi
}

# 執行日志查看
cmd_logs() {
    local log_file="server.log"
    local follow_mode=false
    local line_count=50
    
    # 解析日志參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow_mode=true
                shift
                ;;
            -n)
                shift
                if [[ $1 =~ ^[0-9]+$ ]]; then
                    line_count=$1
                    shift
                else
                    print_error "無效的行數: $1"
                    exit 1
                fi
                ;;
            *)
                print_error "未知選項: $1"
                echo "使用 $0 help 查看幫助"
                exit 1
                ;;
        esac
    done
    
    print_title "📋 查看服務日志"
    echo ""
    
    if [ ! -f "$log_file" ]; then
        print_error "日志文件不存在: $log_file"
        print_info "請先啟動服務以生成日志"
        exit 1
    fi
    
    if [ "$follow_mode" = true ]; then
        print_info "持續查看日志 (按 Ctrl+C 退出)"
        echo ""
        tail -f "$log_file"
    else
        print_info "顯示最後 $line_count 行日志"
        echo ""
        tail -n "$line_count" "$log_file"
        echo ""
        print_info "使用 '$0 logs --follow' 持續查看日志"
    fi
}

# 執行構建
cmd_build() {
    print_title "🔨 構建 YT-MP3 服務"
    echo ""
    
    if [ -f "build.sh" ]; then
        chmod +x build.sh
        ./build.sh
    else
        print_error "找不到構建腳本 build.sh"
        exit 1
    fi
}

# 執行清理
cmd_clean() {
    print_title "🧹 清理臨時文件"
    echo ""
    
    local files_to_clean=(
        "server.pid"
        "server.log"
        "target/"
        "*.log"
    )
    
    print_step "清理以下文件和目錄："
    for item in "${files_to_clean[@]}"; do
        echo "  - $item"
    done
    echo ""
    
    read -p "確認清理? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for item in "${files_to_clean[@]}"; do
            if [[ "$item" == "*"* ]]; then
                # 使用 find 處理通配符
                find . -maxdepth 1 -name "$item" -type f -delete 2>/dev/null || true
            elif [ -f "$item" ]; then
                rm -f "$item"
                print_success "已刪除文件: $item"
            elif [ -d "$item" ]; then
                rm -rf "$item"
                print_success "已刪除目錄: $item"
            fi
        done
        print_success "清理完成"
    else
        print_info "已取消清理"
    fi
}

# 安裝依賴
cmd_install() {
    print_title "📦 安裝依賴"
    echo ""
    
    print_step "檢查 Rust 工具鏈..."
    if ! command -v cargo > /dev/null 2>&1; then
        print_error "未找到 cargo，請先安裝 Rust"
        print_info "安裝命令: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    
    print_success "Rust 工具鏈已安裝"
    
    print_step "更新 Rust 工具鏈..."
    rustup update
    
    print_step "檢查項目依賴..."
    cargo check
    
    print_success "依賴檢查完成"
    
    print_step "檢查額外工具..."
    
    # 檢查 yt-dlp
    if [ ! -f "bin/yt-dlp.exe" ] && [ ! -f "bin/yt-dlp" ]; then
        print_warning "未找到 yt-dlp"
        print_info "請從 https://github.com/yt-dlp/yt-dlp/releases 下載並放到 bin/ 目錄"
    else
        print_success "yt-dlp 已就緒"
    fi
    
    print_success "安裝檢查完成"
}

# 顯示快速狀態
show_quick_status() {
    echo ""
    echo -e "${BOLD}快速狀態:${NC}"
    if quick_status_check; then
        print_success "服務正在運行"
        
        # 檢查端口
        if netstat -an 2>/dev/null | grep -q ":3000.*LISTEN" || 
           ss -ln 2>/dev/null | grep -q ":3000"; then
            print_success "HTTP 端口 (3000) 正常"
        else
            print_warning "HTTP 端口 (3000) 異常"
        fi
        
        if netstat -an 2>/dev/null | grep -q ":3443.*LISTEN" || 
           ss -ln 2>/dev/null | grep -q ":3443"; then
            print_success "HTTPS 端口 (3443) 正常"
        else
            print_warning "HTTPS 端口 (3443) 異常"
        fi
        
        echo ""
        print_info "訪問地址:"
        echo "  🌐 HTTP:  http://127.0.0.1:3000"
        echo "  🔒 HTTPS: https://127.0.0.1:3443"
    else
        print_warning "服務未運行"
        echo ""
        print_info "使用 '$0 start' 啟動服務"
    fi
}

# 主函數
main() {
    # 如果沒有參數，顯示幫助和快速狀態
    if [ $# -eq 0 ]; then
        show_banner
        show_quick_status
        echo ""
        echo -e "${BOLD}常用命令:${NC}"
        echo "  $0 start     - 啟動服務"
        echo "  $0 stop      - 停止服務"
        echo "  $0 status    - 查看狀態"
        echo "  $0 logs      - 查看日志"
        echo "  $0 help      - 顯示幫助"
        echo ""
        return 0
    fi
    
    local command=$1
    shift
    
    case $command in
        start)
            cmd_start "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        restart)
            cmd_restart "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        logs)
            cmd_logs "$@"
            ;;
        build)
            cmd_build "$@"
            ;;
        clean)
            cmd_clean "$@"
            ;;
        install)
            cmd_install "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            echo "使用 '$0 help' 查看可用命令"
            exit 1
            ;;
    esac
}

# 錯誤處理
trap 'print_error "服務管理過程中出現錯誤"' ERR

# 執行主函數
main "$@"