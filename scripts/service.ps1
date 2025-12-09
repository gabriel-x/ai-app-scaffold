# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param([string]$cmd = "help")

# 定义颜色常量
$RED = "\u001b[0;31m"
$GREEN = "\u001b[0;32m"
$YELLOW = "\u001b[1;33m"
$BLUE = "\u001b[0;34m"
$NC = "\u001b[0m" # No Color

# 打印带颜色的消息
function Print-Message {
    param(
        [string]$Color,
        [string]$Message
    )
    Write-Host -ForegroundColor $Color "$Message"
}

# 显示横幅
function Print-Banner {
    param([string]$Message)
    Print-Message $BLUE "======================================"
    Print-Message $BLUE "$Message"
    Print-Message $BLUE "======================================"
}

# 脚本路径和项目根目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT = Split-Path -Parent $SCRIPT_DIR

# 模块目录
$FE_DIR = Join-Path $ROOT "frontend"
$NODE_DIR = Join-Path $ROOT "backend-node"
$PY_DIR = Join-Path $ROOT "backend-python"

# 各模块的管理脚本路径
$FE_SCRIPT = Join-Path $FE_DIR "scripts\client-manager.ps1"
$NODE_SCRIPT = Join-Path $NODE_DIR "scripts\server-manager.ps1"
$PY_SCRIPT = Join-Path $PY_DIR "scripts\server-manager.ps1"

# 检查服务是否运行
function Is-Running {
    param([string]$PidFile)
    if (Test-Path $PidFile) {
        $pid = Get-Content $PidFile
        try {
            Get-Process -Id $pid | Out-Null
            return $true
        } catch {
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    return $false
}

# 启动前端服务
function Start-Frontend {
    Print-Message $BLUE "启动前端服务..."
    & $FE_SCRIPT start
    return $LASTEXITCODE
}

# 停止前端服务
function Stop-Frontend {
    Print-Message $BLUE "停止前端服务..."
    & $FE_SCRIPT stop
    return $LASTEXITCODE
}

# 查看前端服务状态
function Status-Frontend {
    Print-Message $BLUE "前端服务状态:"
    & $FE_SCRIPT status
    return $LASTEXITCODE
}

# 重启前端服务
function Restart-Frontend {
    Print-Message $BLUE "重启前端服务..."
    Stop-Frontend
    Start-Sleep -Seconds 3
    Start-Frontend
    return $LASTEXITCODE
}

# 启动后端Node服务
function Start-Node {
    Print-Message $BLUE "启动后端Node服务..."
    & $NODE_SCRIPT start
    return $LASTEXITCODE
}

# 停止后端Node服务
function Stop-Node {
    Print-Message $BLUE "停止后端Node服务..."
    & $NODE_SCRIPT stop
    return $LASTEXITCODE
}

# 查看后端Node服务状态
function Status-Node {
    Print-Message $BLUE "后端Node服务状态:"
    & $NODE_SCRIPT status
    return $LASTEXITCODE
}

# 重启后端Node服务
function Restart-Node {
    Print-Message $BLUE "重启后端Node服务..."
    Stop-Node
    Start-Sleep -Seconds 3
    Start-Node
    return $LASTEXITCODE
}

# 启动后端Python服务
function Start-Python {
    Print-Message $BLUE "启动后端Python服务..."
    & $PY_SCRIPT start
    return $LASTEXITCODE
}

# 停止后端Python服务
function Stop-Python {
    Print-Message $BLUE "停止后端Python服务..."
    & $PY_SCRIPT stop
    return $LASTEXITCODE
}

# 查看后端Python服务状态
function Status-Python {
    Print-Message $BLUE "后端Python服务状态:"
    & $PY_SCRIPT status
    return $LASTEXITCODE
}

# 重启后端Python服务
function Restart-Python {
    Print-Message $BLUE "重启后端Python服务..."
    Stop-Python
    Start-Sleep -Seconds 3
    Start-Python
    return $LASTEXITCODE
}

# 启动所有服务
function Start-All {
    Print-Banner "Start All Services"
    Start-Frontend
    Start-Node
    Start-Python
}

# 停止所有服务
function Stop-All {
    Print-Banner "Stop All Services"
    Stop-Frontend
    Stop-Node
    Stop-Python
}

# 重启所有服务
function Restart-All {
    Print-Banner "Restart All Services"
    Restart-Frontend
    Restart-Node
    Restart-Python
}

# 查看所有服务状态
function Status-All {
    Print-Banner "Services Status"
    Status-Frontend
    Write-Host
    Status-Node
    Write-Host
    Status-Python
}

# 显示帮助信息
function Show-Help {
    Print-Banner "Service Management Script"
    Write-Host ""
    Write-Host "使用方法: $($MyInvocation.MyCommand.Name) {start|stop|restart|status|start:frontend|stop:frontend|restart:frontend|status:frontend|start:node|stop:node|restart:node|status:node|start:python|stop:python|restart:python|status:python|help}"
    Write-Host ""
    Write-Host "命令说明:"
    Write-Host "  start               - 启动所有服务"
    Write-Host "  stop                - 停止所有服务"
    Write-Host "  restart             - 重启所有服务"
    Write-Host "  status              - 查看所有服务状态"
    Write-Host "  start:frontend      - 启动前端服务"
    Write-Host "  stop:frontend       - 停止前端服务"
    Write-Host "  restart:frontend    - 重启前端服务"
    Write-Host "  status:frontend     - 查看前端服务状态"
    Write-Host "  start:node          - 启动后端Node服务"
    Write-Host "  stop:node           - 停止后端Node服务"
    Write-Host "  restart:node        - 重启后端Node服务"
    Write-Host "  status:node         - 查看后端Node服务状态"
    Write-Host "  start:python        - 启动后端Python服务"
    Write-Host "  stop:python         - 停止后端Python服务"
    Write-Host "  restart:python      - 重启后端Python服务"
    Write-Host "  status:python       - 查看后端Python服务状态"
    Write-Host "  help                - 显示帮助信息"
    Write-Host ""
}

# 主函数
switch ($cmd) {
    "start" {
        Start-All
    }
    "stop" {
        Stop-All
    }
    "restart" {
        Restart-All
    }
    "status" {
        Status-All
    }
    "start:frontend" {
        Print-Banner "Start Frontend"
        Start-Frontend
    }
    "stop:frontend" {
        Print-Banner "Stop Frontend"
        Stop-Frontend
    }
    "restart:frontend" {
        Print-Banner "Restart Frontend"
        Restart-Frontend
    }
    "status:frontend" {
        Print-Banner "Frontend Status"
        Status-Frontend
    }
    "start:node" {
        Print-Banner "Start Node Backend"
        Start-Node
    }
    "stop:node" {
        Print-Banner "Stop Node Backend"
        Stop-Node
    }
    "restart:node" {
        Print-Banner "Restart Node Backend"
        Restart-Node
    }
    "status:node" {
        Print-Banner "Node Backend Status"
        Status-Node
    }
    "start:python" {
        Print-Banner "Start Python Backend"
        Start-Python
    }
    "stop:python" {
        Print-Banner "Stop Python Backend"
        Stop-Python
    }
    "restart:python" {
        Print-Banner "Restart Python Backend"
        Restart-Python
    }
    "status:python" {
        Print-Banner "Python Backend Status"
        Status-Python
    }
    "help" {
        Show-Help
    }
    default {
        Print-Message $RED "错误: 未知命令 '$cmd'"
        Write-Host ""
        Show-Help
    }
}
