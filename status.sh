#!/bin/bash

# YT-MP3 Service Status Script
# 服務狀態檢查腳本

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 函數：打印帶顏色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_step() { echo -e "${PURPLE}🔍 $1${NC}"; }
print_data() { echo -e "${CYAN}📊 $1${NC}"; }

# 服務相關變量
PID_FILE="server.pid"
LOG_FILE="server.log"

# 檢查服務進程狀態
check_process_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_success "服務正在運行"
            print_data "PID: $pid"
            
            # 獲取進程詳細信息
            if command -v ps > /dev/null 2>&1; then
                local process_info=$(ps -p "$pid" -o pid,ppid,user,pcpu,pmem,etime,cmd --no-headers 2>/dev/null || true)
                if [ -n "$process_info" ]; then
                    echo ""
                    print_data "進程詳細信息:"
                    echo "  PID    PPID   USER     %CPU  %MEM  運行時間   命令"
                    echo "  $process_info"
                fi
            fi
            
            return 0
        else
            print_warning "PID文件存在但進程未運行"
            print_info "清理無效的PID文件..."
            rm -f "$PID_FILE"
            return 1
        fi
    else
        print_error "服務未運行 (沒有PID文件)"
        return 1
    fi
}

# 檢查端口狀態
check_port_status() {
    print_step "檢查端口狀態..."
    
    local ports=(3000 3443)
    local port_names=("HTTP" "HTTPS")
    local all_ports_ok=true
    
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local name=${port_names[$i]}
        
        # 檢查端口是否被監聽
        local listening=false
        local pid=""
        
        # 嘗試不同的方法檢查端口
        if command -v netstat > /dev/null 2>&1; then
            if netstat -an 2>/dev/null | grep -q ":${port}.*LISTEN"; then
                listening=true
                pid=$(netstat -tlnp 2>/dev/null | grep ":${port} " | awk '{print $7}' | cut -d'/' -f1 | head -1)
            fi
        elif command -v ss > /dev/null 2>&1; then
            if ss -ln 2>/dev/null | grep -q ":${port}"; then
                listening=true
                pid=$(ss -tlnp 2>/dev/null | grep ":${port} " | grep -o 'pid=[0-9]*' | cut -d'=' -f2 | head -1)
            fi
        fi
        
        if [ "$listening" = true ]; then
            print_success "${name} 端口 ${port} 正在監聽"
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                print_data "  由進程 ${pid} 佔用"
            fi
        else
            print_error "${name} 端口 ${port} 未監聽"
            all_ports_ok=false
        fi
    done
    
    return $( [ "$all_ports_ok" = true ] && echo 0 || echo 1 )
}

# 測試服務響應
test_service_response() {
    print_step "測試服務響應..."
    
    local urls=("http://127.0.0.1:3000" "https://127.0.0.1:3443")
    local names=("HTTP" "HTTPS")
    local all_tests_ok=true
    
    for i in "${!urls[@]}"; do
        local url=${urls[$i]}
        local name=${names[$i]}
        
        print_info "測試 ${name}: ${url}"
        
        # 使用curl測試響應
        if command -v curl > /dev/null 2>&1; then
            local response_code=""
            if [ "$name" = "HTTPS" ]; then
                response_code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
            else
                response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
            fi
            
            if [ "$response_code" = "200" ]; then
                print_success "  ${name} 響應正常 (HTTP $response_code)"
            elif [ "$response_code" != "000" ]; then
                print_warning "  ${name} 響應異常 (HTTP $response_code)"
                all_tests_ok=false
            else
                print_error "  ${name} 連接失敗"
                all_tests_ok=false
            fi
        else
            print_warning "  無法測試響應 (curl 未安裝)"
        fi
    done
    
    return $( [ "$all_tests_ok" = true ] && echo 0 || echo 1 )
}

# 檢查系統資源使用
check_system_resources() {
    print_step "檢查系統資源使用..."
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            # CPU和內存使用情況
            if command -v ps > /dev/null 2>&1; then
                local cpu_mem=$(ps -p "$pid" -o pcpu,pmem --no-headers 2>/dev/null || echo "N/A N/A")
                print_data "CPU使用率: $(echo $cpu_mem | cut -d' ' -f1)%"
                print_data "內存使用率: $(echo $cpu_mem | cut -d' ' -f2)%"
            fi
            
            # 打開的文件描述符數量
            if [ -d "/proc/$pid/fd" ]; then
                local fd_count=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
                print_data "打開的文件描述符: $fd_count"
            fi
            
            # 線程數量
            if [ -d "/proc/$pid/task" ]; then
                local thread_count=$(ls /proc/$pid/task 2>/dev/null | wc -l)
                print_data "線程數量: $thread_count"
            fi
        fi
    fi
    
    # 磁盤使用情況
    if command -v df > /dev/null 2>&1; then
        local disk_usage=$(df -h . | tail -1 | awk '{print $5}')
        print_data "當前目錄磁盤使用: $disk_usage"
    fi
}

# 檢查日志文件
check_log_status() {
    print_step "檢查日志狀態..."
    
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(ls -lh "$LOG_FILE" | awk '{print $5}')
        local log_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        print_success "日志文件存在: $LOG_FILE"
        print_data "  大小: $log_size"
        print_data "  行數: $log_lines"
        
        # 檢查最近的錯誤
        if command -v grep > /dev/null 2>&1; then
            local error_count=$(grep -c -i "error\|fail\|panic" "$LOG_FILE" 2>/dev/null || echo "0")
            if [ "$error_count" -gt 0 ]; then
                print_warning "  發現 $error_count 個錯誤日志"
                echo ""
                print_info "最近的錯誤日志:"
                grep -i "error\|fail\|panic" "$LOG_FILE" | tail -3 | while read line; do
                    echo "    $line"
                done
            else
                print_success "  沒有發現錯誤日志"
            fi
        fi
        
        # 顯示最近的日志
        echo ""
        print_info "最近的日志 (最後5行):"
        tail -5 "$LOG_FILE" | while read line; do
            echo "    $line"
        done
    else
        print_warning "日志文件不存在: $LOG_FILE"
    fi
}

# 檢查必要文件
check_files() {
    print_step "檢查必要文件..."
    
    local files=(
        "bin/server.exe:服務器可執行文件"
        "bin/server:服務器可執行文件"
        "bin/cert-gen.exe:證書生成工具"
        "bin/cert-gen:證書生成工具"
        "certs/cert.pem:SSL證書"
        "certs/key.pem:SSL私鑰"
        "bin/yt-dlp.exe:YouTube下載工具"
        "bin/yt-dlp:YouTube下載工具"
    )
    
    for item in "${files[@]}"; do
        local file=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        
        if [ -f "$file" ]; then
            local size=$(ls -lh "$file" | awk '{print $5}')
            print_success "$desc: $file ($size)"
        else
            if [[ "$file" == *".exe" ]] || [[ "$desc" == *"工具"* ]]; then
                print_warning "$desc: $file (不存在)"
            else
                print_error "$desc: $file (不存在)"
            fi
        fi
    done
}

# 顯示服務概覽
show_service_overview() {
    echo ""
    echo "========================================="
    echo "📋 服務概覽"
    echo "========================================="
    
    # 檢查整體狀態
    local service_running=false
    local ports_ok=false
    local response_ok=false
    
    if check_process_status; then
        service_running=true
    fi
    
    if check_port_status; then
        ports_ok=true
    fi
    
    if [ "$service_running" = true ]; then
        if test_service_response; then
            response_ok=true
        fi
    fi
    
    echo ""
    print_step "整體狀態評估:"
    
    if [ "$service_running" = true ] && [ "$ports_ok" = true ] && [ "$response_ok" = true ]; then
        print_success "🟢 服務運行正常"
    elif [ "$service_running" = true ] && [ "$ports_ok" = true ]; then
        print_warning "🟡 服務運行但響應異常"
    elif [ "$service_running" = true ]; then
        print_warning "🟡 服務運行但端口異常"
    else
        print_error "🔴 服務未運行"
    fi
    
    echo ""
    print_info "可用操作:"
    if [ "$service_running" = false ]; then
        echo "  🚀 啟動服務: ./start.sh"
    else
        echo "  🛑 停止服務: ./stop.sh"
        echo "  🔄 重啟服務: ./stop.sh && ./start.sh"
    fi
    echo "  📊 查看日志: tail -f $LOG_FILE"
    echo "  🌐 訪問服務: http://127.0.0.1:3000"
}

# 主函數
main() {
    echo "========================================="
    echo "🔍 YT-MP3 Service 狀態檢查"
    echo "========================================="
    
    # 解析參數
    local detailed=false
    local watch_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--detailed)
                detailed=true
                shift
                ;;
            -w|--watch)
                watch_mode=true
                shift
                ;;
            -h|--help)
                echo "使用方法: $0 [選項]"
                echo ""
                echo "選項:"
                echo "  -d, --detailed  顯示詳細信息"
                echo "  -w, --watch     監控模式 (每5秒刷新)"
                echo "  -h, --help      顯示此幫助信息"
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
    
    if [ "$watch_mode" = true ]; then
        print_info "監控模式啟動 (按 Ctrl+C 退出)"
        while true; do
            clear
            main --detailed
            echo ""
            print_info "$(date) - 下次刷新: 5秒後"
            sleep 5
        done
    else
        show_service_overview
        
        if [ "$detailed" = true ]; then
            echo ""
            check_system_resources
            echo ""
            check_log_status
            echo ""
            check_files
        fi
    fi
}

# 錯誤處理
trap 'print_error "狀態檢查過程中出現錯誤"' ERR

# 執行主函數
main "$@"