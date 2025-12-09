#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail

# 后端Node服务管理脚本
# 使用方法: ./server-manager.sh start|start_prod|stop|restart|status|logs|test

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
BACKEND_DIR="$PROJECT_ROOT/backend-node"
PID_FILE="$PROJECT_ROOT/.node.pid"
LOG_FILE="$BACKEND_DIR/logs/backend.log"

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

# 加载后端特定的环境变量
if [ -f "$BACKEND_DIR/.env" ]; then
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
    done < "$BACKEND_DIR/.env"
fi

# 设置默认端口和端口范围
# 缺省后端端口号是10000，允许的动态范围是10000-10099
BACKEND_DEFAULT_PORT=10000
BACKEND_PORT_RANGE="10000-10099"

# 从.env文件读取端口配置
if [ -f "$PROJECT_ROOT/.env" ]; then
    # 读取BACKEND_PORT
    BACKEND_PORT_FILEVAL=$(grep -E '^[[:space:]]*BACKEND_PORT=' "$PROJECT_ROOT/.env" | tail -n 1 | sed -E 's/^[^=]+=(.*)$/\1/' | tr -d '[:space:]')
    if [ -n "$BACKEND_PORT_FILEVAL" ]; then
        BACKEND_PORT="$BACKEND_PORT_FILEVAL"
    else
        BACKEND_PORT="$BACKEND_DEFAULT_PORT"
    fi
    # 读取BACKEND_PORT_RANGE
    BACKEND_PORT_RANGE_FILEVAL=$(grep -E '^[[:space:]]*BACKEND_PORT_RANGE=' "$PROJECT_ROOT/.env" | tail -n 1 | sed -E 's/^[^=]+=(.*)$/\1/' | tr -d '[:space:]')
    if [ -n "$BACKEND_PORT_RANGE_FILEVAL" ]; then
        BACKEND_PORT_RANGE="$BACKEND_PORT_RANGE_FILEVAL"
    fi
else
    BACKEND_PORT="$BACKEND_DEFAULT_PORT"
fi

# 提取端口范围的起始和结束值
IFS='-' read -r BACKEND_PORT_START BACKEND_PORT_END <<< "$BACKEND_PORT_RANGE"

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
            if echo "$cmd" | grep -q "$BACKEND_DIR\|node.*$port\|npm.*run.*dev"; then
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
BACKEND_PORT=$(find_available_port $BACKEND_PORT_START $BACKEND_PORT_END $BACKEND_PORT)
if [ -z "$BACKEND_PORT" ]; then
    print_message $RED "错误: 无法在端口范围 $BACKEND_PORT_RANGE 内找到可用端口"
    exit 1
fi

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

# 检查后端服务是否运行
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
        if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 0
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$BACKEND_PORT "; then
            return 0
        fi
    fi
    return 1
}

# 启动后端服务（开发模式）
start_backend() {
    if is_running; then
        print_message $YELLOW "后端服务已在运行中 (PID: $(cat "$PID_FILE"))"
        return 0
    fi
    
    # 检查端口是否被占用
    if check_port; then
        print_message $RED "错误: 端口 $BACKEND_PORT 已被占用"
        print_message $YELLOW "请使用以下命令查看占用进程: lsof -i :$BACKEND_PORT"
        return 1
    fi
    
    print_message $BLUE "启动后端服务..."
    
    # 确保在后端目录
    cd "$BACKEND_DIR" || {
        print_message $RED "错误: 无法切换到后端目录: $BACKEND_DIR"
        return 1
    }
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        print_message $YELLOW "安装后端依赖..."
        if command -v pnpm >/dev/null 2>&1; then
            pnpm install || {
                print_message $RED "错误: 后端依赖安装失败"
                return 1
            }
        else
            npm install || {
                print_message $RED "错误: 后端依赖安装失败"
                return 1
            }
        fi
    fi
    
    ensure_log_dir
    
    # 启动后端服务 (使用 dev 用于开发环境)
    print_message $BLUE "DEBUG: 计划使用端口 BACKEND_PORT=$BACKEND_PORT"
    if command -v pnpm >/dev/null 2>&1; then
        nohup pnpm run dev > "$LOG_FILE" 2>&1 &
    else
        nohup npm run dev > "$LOG_FILE" 2>&1 &
    fi
    local pid=$!
    
    # 保存PID
    echo $pid > "$PID_FILE"
    
    # 等待服务启动
    sleep 5
    
    if is_running; then
        print_message $GREEN "✓ 后端服务启动成功 (PID: $pid)"
        print_message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        
        # 检查健康状态
        if command -v curl >/dev/null 2>&1; then
            sleep 2
            if curl -s "http://localhost:$BACKEND_PORT/health" >/dev/null 2>&1; then
                print_message $GREEN "✓ 后端服务健康检查通过"
            else
                print_message $YELLOW "⚠ 后端服务启动但健康检查失败"
            fi
        fi
        return 0
    else
        print_message $RED "✗ 后端服务启动失败"
        print_message $YELLOW "请查看日志: $LOG_FILE"
        return 1
    fi
}

# 启动后端服务（生产模式）
start_backend_prod() {
    if is_running; then
        print_message $YELLOW "后端服务已在运行中 (PID: $(cat "$PID_FILE"))"
        return 0
    fi

    # 检查端口是否被占用
    if check_port; then
        print_message $RED "错误: 端口 $BACKEND_PORT 已被占用"
        print_message $YELLOW "请使用以下命令查看占用进程: lsof -i :$BACKEND_PORT"
        return 1
    fi

    print_message $BLUE "以生产模式启动后端服务..."

    # 确保在后端目录
    cd "$BACKEND_DIR" || {
        print_message $RED "错误: 无法切换到后端目录: $BACKEND_DIR"
        return 1
    }

    # 安装依赖
    if [ ! -d "node_modules" ]; then
        print_message $YELLOW "安装后端依赖..."
        if command -v pnpm >/dev/null 2>&1; then
            pnpm install || {
                print_message $RED "错误: 后端依赖安装失败"
                return 1
            }
        else
            npm install || {
                print_message $RED "错误: 后端依赖安装失败"
                return 1
            }
        fi
    fi

    ensure_log_dir

    # 构建项目
    print_message $BLUE "构建后端项目..."
    if command -v pnpm >/dev/null 2>&1; then
        pnpm run build || {
            print_message $RED "错误: 后端构建失败"
            return 1
        }
    else
        npm run build || {
            print_message $RED "错误: 后端构建失败"
            return 1
        }
    fi

    # 设置生产环境变量
    export NODE_ENV=production
    export BACKEND_PORT="${BACKEND_PORT}"

    # 启动生产服务
    if command -v pnpm >/dev/null 2>&1; then
        nohup pnpm run start > "$LOG_FILE" 2>&1 &
    else
        nohup npm run start > "$LOG_FILE" 2>&1 &
    fi
    local pid=$!
    echo $pid > "$PID_FILE"

    # 等待服务启动
    sleep 5

    if is_running; then
        print_message $GREEN "✓ 后端服务(生产)启动成功 (PID: $pid)"
        print_message $BLUE "API地址: http://localhost:$BACKEND_PORT"

        # 健康检查
        if command -v curl >/dev/null 2>&1; then
            sleep 2
            if curl -s "http://localhost:$BACKEND_PORT/health" >/dev/null 2>&1; then
                print_message $GREEN "✓ 后端服务健康检查通过"
            else
                print_message $YELLOW "⚠ 后端服务启动但健康检查失败"
            fi
        fi
        return 0
    else
        print_message $RED "✗ 后端服务(生产)启动失败"
        print_message $YELLOW "请查看日志: $LOG_FILE"
        return 1
    fi
}

# 停止后端服务
stop_backend() {
    if ! is_running; then
        # 即使没有PID文件，也尝试根据端口清理残留进程
        if check_port; then
            print_message $YELLOW "检测到端口 $BACKEND_PORT 有进程监听，尝试清理..."
            if command -v lsof >/dev/null 2>&1; then
                local port_pids=$(lsof -ti :$BACKEND_PORT 2>/dev/null)
                if [ -n "$port_pids" ]; then
                    print_message $YELLOW "清理残留的端口监听进程..."
                    echo "$port_pids" | xargs -r kill -9 2>/dev/null
                fi
            fi
            sleep 2
            if check_port; then
                print_message $RED "✗ 警告: 端口 $BACKEND_PORT 仍被占用"
                if command -v lsof >/dev/null 2>&1; then
                    local remaining_pids=$(lsof -ti :$BACKEND_PORT 2>/dev/null)
                    if [ -n "$remaining_pids" ]; then
                        print_message $YELLOW "占用端口的进程: $remaining_pids"
                    fi
                fi
                return 1
            else
                print_message $GREEN "✓ 已清理端口占用，后端服务未运行"
                return 0
            fi
        fi
        print_message $YELLOW "后端服务未运行"
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    print_message $BLUE "停止后端服务 (PID: $pid)..."
    
    # 1. 先杀死主进程
    kill -TERM "$pid" 2>/dev/null
    
    # 2. 杀死所有与这个主进程相关的子进程
    if ps -p "$pid" > /dev/null 2>&1; then
        # 等待一下，让主进程有机会自己清理
        sleep 2
        
        # 如果主进程还在，杀死整个进程树
        if ps -p "$pid" > /dev/null 2>&1; then
            # 使用pstree找到所有子进程并杀死
            if command -v pstree >/dev/null 2>&1; then
                local child_pids=$(pstree -p "$pid" | grep -o '([0-9]*)' | grep -o '[0-9]*')
                if [ -n "$child_pids" ]; then
                    print_message $YELLOW "杀死主进程及其所有子进程..."
                    echo "$child_pids" | xargs -r kill -9 2>/dev/null
                fi
            else
                # 没有pstree的话，杀死主进程
                print_message $YELLOW "强制杀死主进程..."
                kill -9 "$pid" 2>/dev/null
            fi
        fi
    fi
    
    # 3. 等待进程结束
    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 15 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    # 4. 如果进程仍在运行，强制杀死
    if ps -p "$pid" > /dev/null 2>&1; then
        print_message $YELLOW "强制停止后端服务..."
        kill -9 "$pid" 2>/dev/null
    fi
    
    # 5. 杀死所有相关的pnpm、tsx、node进程
    print_message $YELLOW "清理所有相关进程..."
    pkill -f "pnpm run dev.*$BACKEND_DIR" 2>/dev/null || true
    pkill -f "tsx watch.*$BACKEND_DIR" 2>/dev/null || true
    pkill -f "node.*$BACKEND_DIR" 2>/dev/null || true
    pkill -f "sh -c tsx watch.*" 2>/dev/null || true
    
    # 6. 额外检查：杀死所有可能残留的node进程（监听指定端口的）
    if command -v lsof >/dev/null 2>&1; then
        local port_pids=$(lsof -ti :$BACKEND_PORT 2>/dev/null)
        if [ -n "$port_pids" ]; then
            print_message $YELLOW "清理残留的端口监听进程..."
            echo "$port_pids" | xargs -r kill -9 2>/dev/null
        fi
    fi
    
    # 7. 使用pkill作为备用方案，杀死可能的npm和node子进程
    pkill -f "npm start" 2>/dev/null || true
    pkill -f "node dist/main.js" 2>/dev/null || true
    pkill -f "node --loader ts-node/esm" 2>/dev/null || true
    pkill -f "tsx watch" 2>/dev/null || true
    
    rm -f "$PID_FILE"
    
    # 8. 验证端口是否已释放
    sleep 2
    if check_port; then
        print_message $RED "✗ 警告: 端口 $BACKEND_PORT 仍被占用，可能需要手动清理"
        if command -v lsof >/dev/null 2>&1; then
            print_message $YELLOW "占用端口的进程: $(lsof -ti :$BACKEND_PORT 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
        fi
        return 1
    else
        print_message $GREEN "✓ 后端服务已完全停止"
        return 0
    fi
}

# 重启后端服务
restart_backend() {
    print_message $BLUE "重启后端服务..."
    stop_backend
    sleep 3
    start_backend
}

# 显示后端服务状态
status_backend() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_message $GREEN "✓ 后端服务正在运行 (PID: $pid)"
        print_message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        
        # 检查端口是否可访问
        if command -v curl >/dev/null 2>&1; then
            if curl -s "http://localhost:$BACKEND_PORT/health" >/dev/null 2>&1; then
                print_message $GREEN "✓ 后端服务健康"
            else
                print_message $YELLOW "⚠ 后端服务进程存在但API不可访问"
            fi
        fi
        return 0
    else
        # 若无PID但端口有监听，提示服务可能在运行（外部启动）
        if check_port; then
            print_message $YELLOW "⚠ 未发现PID文件，但检测到端口 $BACKEND_PORT 有服务在运行"
            print_message $BLUE "API地址: http://localhost:$BACKEND_PORT"
            return 0
        fi
        print_message $RED "✗ 后端服务未运行"
        return 1
    fi
}

# 显示后端服务日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_message $BLUE "后端服务日志 (最后50行):"
        tail -n 50 "$LOG_FILE"
    else
        print_message $YELLOW "日志文件不存在: $LOG_FILE"
    fi
}

# 运行后端测试
run_tests() {
    print_message $BLUE "运行后端测试..."
    
    # 确保在后端目录
    cd "$BACKEND_DIR" || {
        print_message $RED "错误: 无法切换到后端目录: $BACKEND_DIR"
        return 1
    }
    
    # 检查是否有测试脚本
    if command -v pnpm >/dev/null 2>&1; then
        if pnpm run | grep -q "test"; then
            pnpm test
        else
            print_message $YELLOW "未找到测试脚本"
            return 1
        fi
    else
        if npm run | grep -q "test"; then
            npm test
        else
            print_message $YELLOW "未找到测试脚本"
            return 1
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo "后端Node服务管理脚本"
    echo ""
    echo "使用方法: $0 {start|start_prod|stop|restart|status|logs|test|help}"
    echo ""
    echo "命令说明:"
    echo "  start     - 启动后端服务(开发模式)"
    echo "  start_prod - 启动后端服务(生产模式)"
    echo "  stop      - 停止后端服务"
    echo "  restart   - 重启后端服务"
    echo "  status    - 查看后端服务状态"
    echo "  logs      - 查看后端服务日志"
    echo "  test      - 运行后端测试"
    echo "  help      - 显示帮助信息"
    echo ""
    echo "API地址: http://localhost:$BACKEND_PORT"
}

# 主函数
case "$1" in
    start)
        start_backend
        ;;
    start_prod)
        start_backend_prod
        ;;
    stop)
        stop_backend
        ;;
    restart)
        restart_backend
        ;;
    status)
        status_backend
        ;;
    logs)
        show_logs
        ;;
    test)
        run_tests
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
