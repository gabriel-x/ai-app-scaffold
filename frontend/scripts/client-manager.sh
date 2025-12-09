#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail

# 前端服务管理脚本
# 使用方法: ./client-manager.sh start|stop|restart|status|logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
PID_FILE="$PROJECT_ROOT/.frontend.pid"
# 按工作区统一规则将前端日志写入 frontend/logs/
LOG_FILE="$FRONTEND_DIR/logs/frontend.log"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env" ]; then
    # 使用while循环逐行读取，避免shell解释特殊字符
    while IFS= read -r line || [ -n "$line" ]; do
        # 跳过注释行和空行
        case "$line" in
            \#*|''|*[[:space:]]*)
                # 检查是否为注释行或空行
                if echo "$line" | grep -q '^[[:space:]]*#' || [ -z "$(echo "$line" | tr -d ' \t')" ]; then
                    continue
                fi
                ;;
        esac
        # 导出有效的环境变量
        if echo "$line" | grep -q '^[A-Za-z_][A-Za-z0-9_]*='; then
            export "$line"
        fi
    done < "$PROJECT_ROOT/.env"
fi

# 加载前端特定的环境变量
if [ -f "$FRONTEND_DIR/.env" ]; then
    # 使用while循环逐行读取，避免shell解释特殊字符
    while IFS= read -r line || [ -n "$line" ]; do
        # 跳过注释行和空行
        case "$line" in
            \#*|''|*[[:space:]]*)
                # 检查是否为注释行或空行
                if echo "$line" | grep -q '^[[:space:]]*#' || [ -z "$(echo "$line" | tr -d ' \t')" ]; then
                    continue
                fi
                ;;
        esac
        # 导出有效的环境变量
        if echo "$line" | grep -q '^[A-Za-z_][A-Za-z0-9_]*='; then
            export "$line"
        fi
    done < "$FRONTEND_DIR/.env"
fi

# 设置默认端口和端口范围
# 缺省前端端口号是10100，允许的动态范围是10100-10199
FRONTEND_DEFAULT_PORT=10100
FRONTEND_PORT_RANGE="10100-10199"

# 从.env文件读取端口配置
if [ -f "$PROJECT_ROOT/.env" ]; then
    # 读取FRONTEND_PORT
    FRONTEND_PORT_FILEVAL=$(grep -E '^[[:space:]]*FRONTEND_PORT=' "$PROJECT_ROOT/.env" | tail -n 1 | sed -E 's/^[^=]+=(.*)$/\1/' | tr -d '[:space:]')
    if [ -n "$FRONTEND_PORT_FILEVAL" ]; then
        FRONTEND_PORT="$FRONTEND_PORT_FILEVAL"
    else
        FRONTEND_PORT="$FRONTEND_DEFAULT_PORT"
    fi
    # 读取FRONTEND_PORT_RANGE
    FRONTEND_PORT_RANGE_FILEVAL=$(grep -E '^[[:space:]]*FRONTEND_PORT_RANGE=' "$PROJECT_ROOT/.env" | tail -n 1 | sed -E 's/^[^=]+=(.*)$/\1/' | tr -d '[:space:]')
    if [ -n "$FRONTEND_PORT_RANGE_FILEVAL" ]; then
        FRONTEND_PORT_RANGE="$FRONTEND_PORT_RANGE_FILEVAL"
    fi
else
    FRONTEND_PORT="$FRONTEND_DEFAULT_PORT"
fi

# 提取端口范围的起始和结束值
IFS='-' read -r FRONTEND_PORT_START FRONTEND_PORT_END <<< "$FRONTEND_PORT_RANGE"

# 检查端口是否被占用的函数
is_port_occupied() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 0
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            return 0
        fi
    fi
    return 1
}

# 检查端口是否为本应用占用的函数
is_app_port() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        local pids=$(lsof -ti :$port 2>/dev/null)
        for pid in $pids; do
            local cmd=$(ps -p $pid -o cmd= 2>/dev/null || true)
            if echo "$cmd" | grep -q "$FRONTEND_DIR\|vite.*$port\|node.*$port"; then
                return 0
            fi
        done
    fi
    return 1
}

# 查找可用端口的函数
find_available_port() {
    local start=$1
    local end=$2
    local current=$3
    
    # 先检查当前端口是否可用或为本应用占用
    if ! is_port_occupied $current || is_app_port $current; then
        echo $current
        return 0
    fi
    
    # 从当前端口开始查找可用端口
    for port in $(seq $current $end); do
        if ! is_port_occupied $port; then
            echo $port
            return 0
        fi
    done
    
    # 如果从当前端口到结束都没有可用端口，从起始端口到当前端口前一个查找
    for port in $(seq $start $((current-1))); do
        if ! is_port_occupied $port; then
            echo $port
            return 0
        fi
    done
    
    # 没有可用端口
    echo ""
    return 1
}

# 确保端口可用
FRONTEND_PORT=$(find_available_port $FRONTEND_PORT_START $FRONTEND_PORT_END $FRONTEND_PORT)
if [ -z "$FRONTEND_PORT" ]; then
    print_message $RED "错误: 无法在端口范围 $FRONTEND_PORT_RANGE 内找到可用端口"
    exit 1
fi

export FRONTEND_PORT
export PORT="$FRONTEND_PORT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 确保日志目录存在
ensure_log_dir() {
    local log_dir="$(dirname "$LOG_FILE")"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi
}

# 检查前端服务是否运行
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# 检查端口是否被占用
check_port() {
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$FRONTEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 0
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$FRONTEND_PORT "; then
            return 0
        fi
    fi
    return 1
}

# 启动前端服务
start_frontend() {
    if is_running; then
        print_message $YELLOW "前端服务已在运行中 (PID: $(cat "$PID_FILE"))"
        return 0
    fi
    
    # 检查端口是否被占用
    if check_port; then
        print_message $RED "错误: 端口 $FRONTEND_PORT 已被占用"
        print_message $YELLOW "请使用以下命令查看占用进程: lsof -i :$FRONTEND_PORT"
        return 1
    fi
    
    print_message $BLUE "启动前端服务..."
    
    # 确保在前端目录
    cd "$FRONTEND_DIR" || {
        print_message $RED "错误: 无法切换到前端目录: $FRONTEND_DIR"
        return 1
    }
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        print_message $YELLOW "安装前端依赖..."
        if command -v pnpm >/dev/null 2>&1; then
            pnpm install || {
                print_message $RED "错误: 前端依赖安装失败"
                return 1
            }
        else
            npm install || {
                print_message $RED "错误: 前端依赖安装失败"
                return 1
            }
        fi
    fi
    
    ensure_log_dir
    
    # 启动前端开发服务器（强制指定端口，使用 --strictPort）
    # 说明：
    # - 使用 --port "$FRONTEND_PORT" 和 --strictPort，确保 Vite 在指定端口启动或直接失败
    # - 通过在脚本级别传参，避免外部环境设置 PORT=5184 等情况覆盖 vite.config.ts 的配置
    print_message $BLUE "DEBUG: 计划使用端口 FRONTEND_PORT=$FRONTEND_PORT, PORT=$PORT"
    if command -v pnpm >/dev/null 2>&1; then
        nohup env FRONTEND_PORT="$FRONTEND_PORT" PORT="$FRONTEND_PORT" pnpm run dev -- --port "$FRONTEND_PORT" --strictPort > "$LOG_FILE" 2>&1 &
    else
        nohup env FRONTEND_PORT="$FRONTEND_PORT" PORT="$FRONTEND_PORT" npm run dev -- --port "$FRONTEND_PORT" --strictPort > "$LOG_FILE" 2>&1 &
    fi
    local pid=$!
    
    # 保存PID
    echo $pid > "$PID_FILE"
    
    # 等待服务启动
    sleep 5
    
    if is_running; then
        print_message $GREEN "✓ 前端服务启动成功 (PID: $pid)"
        print_message $BLUE "访问地址: http://localhost:$FRONTEND_PORT"
        
        # 记录实际使用的端口
        print_message $BLUE "实际使用的端口: $FRONTEND_PORT"
        
        # 检查服务是否可访问
        if command -v curl >/dev/null 2>&1; then
            sleep 3
            print_message $BLUE "检查服务可访问性..."
            if curl -s "http://localhost:$FRONTEND_PORT" >/dev/null 2>&1; then
                print_message $GREEN "✓ 前端服务可正常访问"
            else
                print_message $YELLOW "⚠ 前端服务启动但暂时无法访问"
                print_message $YELLOW "可能的原因: 服务仍在启动中，或端口 $FRONTEND_PORT 未正确响应"
            fi
        else
            print_message $YELLOW "⚠ 无法检查服务可访问性 (curl 命令不可用)"
        fi
        return 0
    else
        print_message $RED "✗ 前端服务启动失败"
        print_message $YELLOW "请查看日志: $LOG_FILE"
        return 1
    fi
}

# 停止前端服务
stop_frontend() {
    if ! is_running; then
        # 即使没有PID文件，也尝试根据端口清理残留进程
        if check_port; then
            print_message $YELLOW "检测到端口 $FRONTEND_PORT 有进程监听，尝试清理..."
            if command -v lsof >/dev/null 2>&1; then
                local port_pids=$(lsof -ti :$FRONTEND_PORT 2>/dev/null)
                if [ -n "$port_pids" ]; then
                    print_message $YELLOW "清理残留的端口监听进程..."
                    echo "$port_pids" | xargs -r kill -9 2>/dev/null
                fi
            fi
            sleep 2
            if check_port; then
                print_message $RED "✗ 警告: 端口 $FRONTEND_PORT 仍被占用"
                if command -v lsof >/dev/null 2>&1; then
                    local remaining_pids=$(lsof -ti :$FRONTEND_PORT 2>/dev/null)
                    if [ -n "$remaining_pids" ]; then
                        print_message $YELLOW "占用端口的进程: $remaining_pids"
                    fi
                fi
                return 1
            else
                print_message $GREEN "✓ 已清理端口占用，前端服务未运行"
                return 0
            fi
        fi
        print_message $YELLOW "前端服务未运行"
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    print_message $BLUE "停止前端服务 (PID: $pid)..."
    
    # 获取进程的子进程列表，确保只杀死本项目相关的进程
    local child_pids=$(pgrep -P "$pid" 2>/dev/null || true)
    
    # 尝试优雅停止主进程
    kill -TERM "$pid" 2>/dev/null
    
    # 等待进程结束
    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 15 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    # 如果主进程仍在运行，强制杀死
    if ps -p "$pid" > /dev/null 2>&1; then
        print_message $YELLOW "强制停止主进程..."
        kill -9 "$pid" 2>/dev/null
    fi
    
    # 清理子进程（只杀死确认的子进程）
    if [ -n "$child_pids" ]; then
        print_message $YELLOW "清理子进程..."
        for child_pid in $child_pids; do
            if ps -p "$child_pid" > /dev/null 2>&1; then
                # 检查子进程是否确实属于我们的项目
                local cmd_line=$(ps -p "$child_pid" -o cmd= 2>/dev/null || true)
                if echo "$cmd_line" | grep -q "$FRONTEND_DIR\|vite.*$FRONTEND_PORT"; then
                    kill -9 "$child_pid" 2>/dev/null || true
                fi
            fi
        done
    fi
    
    # 只在确认是本项目进程时才清理端口占用
    if command -v lsof >/dev/null 2>&1; then
        local port_pids=$(lsof -ti :$FRONTEND_PORT 2>/dev/null)
        if [ -n "$port_pids" ]; then
            print_message $YELLOW "清理本项目的端口监听进程..."
            for port_pid in $port_pids; do
                local cmd_line=$(ps -p "$port_pid" -o cmd= 2>/dev/null || true)
                if echo "$cmd_line" | grep -q "$FRONTEND_DIR\|vite.*$FRONTEND_PORT"; then
                    kill -9 "$port_pid" 2>/dev/null || true
                fi
            done
        fi
    fi
    
    rm -f "$PID_FILE"
    
    # 验证端口是否已释放
    sleep 2
    if check_port; then
        print_message $RED "✗ 警告: 端口 $FRONTEND_PORT 仍被占用"
        if command -v lsof >/dev/null 2>&1; then
            local remaining_pids=$(lsof -ti :$FRONTEND_PORT 2>/dev/null)
            if [ -n "$remaining_pids" ]; then
                print_message $YELLOW "占用端口的进程详情:"
                for remaining_pid in $remaining_pids; do
                    local cmd_line=$(ps -p "$remaining_pid" -o pid,cmd= 2>/dev/null || true)
                    if [ -n "$cmd_line" ]; then
                        print_message $YELLOW "  $cmd_line"
                    fi
                done
                print_message $YELLOW "提示: 如果这些进程不属于本项目，请手动处理"
            fi
        fi
        return 1
    else
        print_message $GREEN "✓ 前端服务已完全停止"
        return 0
    fi
}

# 重启前端服务
restart_frontend() {
    print_message $BLUE "重启前端服务..."
    stop_frontend
    sleep 3
    start_frontend
}

# 显示前端服务状态
status_frontend() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_message $GREEN "✓ 前端服务正在运行 (PID: $pid)"
        print_message $BLUE "访问地址: http://localhost:$FRONTEND_PORT"
        
        # 记录实际使用的端口
        print_message $BLUE "实际使用的端口: $FRONTEND_PORT"
        
        # 检查端口是否可访问
        if command -v curl >/dev/null 2>&1; then
            print_message $BLUE "检查服务可访问性..."
            if curl -s "http://localhost:$FRONTEND_PORT" >/dev/null 2>&1; then
                print_message $GREEN "✓ 前端服务可正常访问"
            else
                print_message $YELLOW "⚠ 前端服务进程存在但页面不可访问"
            fi
        fi
        return 0
    else
        # 若无PID但端口有监听，提示服务可能在运行（外部启动）
        if check_port; then
            print_message $YELLOW "⚠ 未发现PID文件，但检测到端口 $FRONTEND_PORT 有服务在运行"
            print_message $BLUE "访问地址: http://localhost:$FRONTEND_PORT"
            return 0
        fi
        print_message $RED "✗ 前端服务未运行"
        return 1
    fi
}

# 显示前端服务日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_message $BLUE "前端服务日志 (最后50行):"
        tail -n 50 "$LOG_FILE"
    else
        print_message $YELLOW "日志文件不存在: $LOG_FILE"
    fi
}

# 显示帮助信息
show_help() {
    echo "前端服务管理脚本"
    echo ""
    echo "使用方法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令说明:"
    echo "  start   - 启动前端服务"
    echo "  stop    - 停止前端服务"
    echo "  restart - 重启前端服务"
    echo "  status  - 查看前端服务状态"
    echo "  logs    - 查看前端服务日志"
    echo "  help    - 显示帮助信息"
    echo ""
    echo "访问地址: http://localhost:$FRONTEND_PORT"
}

# 主函数
case "$1" in
    start)
        start_frontend
        ;;
    stop)
        stop_frontend
        ;;
    restart)
        restart_frontend
        ;;
    status)
        status_frontend
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_message $RED "错误: 未知命令 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac

exit $?
