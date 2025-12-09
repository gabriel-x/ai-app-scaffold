#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)

# 总控服务管理脚本
# 使用方法: ./service.sh start|stop|restart|status|start:frontend|stop:frontend|restart:frontend|status:frontend|start:node|stop:node|restart:node|status:node|start:python|stop:python|restart:python|status:python

# 脚本路径和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

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

# 显示横幅
print_banner() {
    local message=$1
    print_message $BLUE "======================================"
    print_message $BLUE "$message"
    print_message $BLUE "======================================"
}

# 模块目录
FE_DIR="$ROOT/frontend"
NODE_DIR="$ROOT/backend-node"
PY_DIR="$ROOT/backend-python"

# PID文件位置（与各模块脚本保持一致）
FE_PID_FILE="$ROOT/.frontend.pid"
NODE_PID_FILE="$ROOT/.node.pid"
PY_PID_FILE="$ROOT/.python.pid"

# 检查服务是否运行
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

# 启动前端服务
start_frontend() {
    if is_running "$FE_PID_FILE"; then
        local pid=$(cat "$FE_PID_FILE")
        print_message $YELLOW "前端服务已在运行中 (PID: $pid)"
        return 0
    fi
    
    print_message $BLUE "启动前端服务..."
    
    # 使用前端模块自己的启动脚本
    "$FE_DIR/scripts/client-manager.sh" start
    return $?
}

# 停止前端服务
stop_frontend() {
    print_message $BLUE "停止前端服务..."
    
    # 使用前端模块自己的停止脚本
    "$FE_DIR/scripts/client-manager.sh" stop
    return $?
}

# 查看前端服务状态
status_frontend() {
    print_message $BLUE "前端服务状态:"
    "$FE_DIR/scripts/client-manager.sh" status
    return $?
}

# 重启前端服务
restart_frontend() {
    print_message $BLUE "重启前端服务..."
    stop_frontend
    sleep 3
    start_frontend
    return $?
}

# 启动后端Node服务
start_node() {
    if is_running "$NODE_PID_FILE"; then
        local pid=$(cat "$NODE_PID_FILE")
        print_message $YELLOW "后端Node服务已在运行中 (PID: $pid)"
        return 0
    fi
    
    print_message $BLUE "启动后端Node服务..."
    
    # 使用后端Node模块自己的启动脚本
    "$NODE_DIR/scripts/server-manager.sh" start
    return $?
}

# 停止后端Node服务
stop_node() {
    print_message $BLUE "停止后端Node服务..."
    
    # 使用后端Node模块自己的停止脚本
    "$NODE_DIR/scripts/server-manager.sh" stop
    return $?
}

# 查看后端Node服务状态
status_node() {
    print_message $BLUE "后端Node服务状态:"
    "$NODE_DIR/scripts/server-manager.sh" status
    return $?
}

# 重启后端Node服务
restart_node() {
    print_message $BLUE "重启后端Node服务..."
    stop_node
    sleep 3
    start_node
    return $?
}

# 启动后端Python服务
start_python() {
    if is_running "$PY_PID_FILE"; then
        local pid=$(cat "$PY_PID_FILE")
        print_message $YELLOW "后端Python服务已在运行中 (PID: $pid)"
        return 0
    fi
    
    print_message $BLUE "启动后端Python服务..."
    
    # 使用后端Python模块自己的启动脚本
    "$PY_DIR/scripts/server-manager.sh" start
    return $?
}

# 停止后端Python服务
stop_python() {
    print_message $BLUE "停止后端Python服务..."
    
    # 使用后端Python模块自己的停止脚本
    "$PY_DIR/scripts/server-manager.sh" stop
    return $?
}

# 查看后端Python服务状态
status_python() {
    print_message $BLUE "后端Python服务状态:"
    "$PY_DIR/scripts/server-manager.sh" status
    return $?
}

# 重启后端Python服务
restart_python() {
    print_message $BLUE "重启后端Python服务..."
    stop_python
    sleep 3
    start_python
    return $?
}

# 启动所有服务
start_all() {
    print_banner "Start All Services"
    start_frontend
    start_node
    start_python
}

# 停止所有服务
stop_all() {
    print_banner "Stop All Services"
    stop_frontend
    stop_node
    stop_python
}

# 重启所有服务
restart_all() {
    print_banner "Restart All Services"
    restart_frontend
    restart_node
    restart_python
}

# 查看所有服务状态
status_all() {
    print_banner "Services Status"
    status_frontend
    echo
    status_node
    echo
    status_python
}

# 显示帮助信息
show_help() {
    print_banner "Service Management Script"
    echo ""
    echo "使用方法: $0 {start|stop|restart|status|start:frontend|stop:frontend|restart:frontend|status:frontend|start:node|stop:node|restart:node|status:node|start:python|stop:python|restart:python|status:python|help}"
    echo ""
    echo "命令说明:"
    echo "  start               - 启动所有服务"
    echo "  stop                - 停止所有服务"
    echo "  restart             - 重启所有服务"
    echo "  status              - 查看所有服务状态"
    echo "  start:frontend      - 启动前端服务"
    echo "  stop:frontend       - 停止前端服务"
    echo "  restart:frontend    - 重启前端服务"
    echo "  status:frontend     - 查看前端服务状态"
    echo "  start:node          - 启动后端Node服务"
    echo "  stop:node           - 停止后端Node服务"
    echo "  restart:node        - 重启后端Node服务"
    echo "  status:node         - 查看后端Node服务状态"
    echo "  start:python        - 启动后端Python服务"
    echo "  stop:python         - 停止后端Python服务"
    echo "  restart:python      - 重启后端Python服务"
    echo "  status:python       - 查看后端Python服务状态"
    echo "  help                - 显示帮助信息"
    echo ""
}

# 主函数
cmd=${1:-help}
case "$cmd" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        status_all
        ;;
    start:frontend)
        print_banner "Start Frontend"
        start_frontend
        ;;
    stop:frontend)
        print_banner "Stop Frontend"
        stop_frontend
        ;;
    restart:frontend)
        print_banner "Restart Frontend"
        restart_frontend
        ;;
    status:frontend)
        print_banner "Frontend Status"
        status_frontend
        ;;
    start:node)
        print_banner "Start Node Backend"
        start_node
        ;;
    stop:node)
        print_banner "Stop Node Backend"
        stop_node
        ;;
    restart:node)
        print_banner "Restart Node Backend"
        restart_node
        ;;
    status:node)
        print_banner "Node Backend Status"
        status_node
        ;;
    start:python)
        print_banner "Start Python Backend"
        start_python
        ;;
    stop:python)
        print_banner "Stop Python Backend"
        stop_python
        ;;
    restart:python)
        print_banner "Restart Python Backend"
        restart_python
        ;;
    status:python)
        print_banner "Python Backend Status"
        status_python
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_message $RED "错误: 未知命令 '$cmd'"
        echo ""
        show_help
        exit 1
        ;;
esac

exit $?
