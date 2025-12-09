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

# 脚本路径和项目根目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend-node"
$PID_FILE = Join-Path $PROJECT_ROOT ".node.pid"
$LOG_FILE = Join-Path $BACKEND_DIR "logs\backend.log"

# 确保日志目录存在
function Ensure-LogDir {
    $logDir = Split-Path -Parent $LOG_FILE
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
}

# 加载环境变量
function Load-Env {
    # 加载项目根目录的环境变量
    if (Test-Path (Join-Path $PROJECT_ROOT ".env")) {
        Get-Content (Join-Path $PROJECT_ROOT ".env") | ForEach-Object {
            $line = $_.Trim()
            # 跳过注释行和空行
            if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
                return
            }
            # 导出有效的环境变量
            if ($line -match '^[A-Za-z_][A-Za-z0-9_]*=') {
                $k, $v = $line -split '=', 2
                Set-Item -Path Env:$k -Value $v
            }
        }
    }

    # 加载后端特定的环境变量
    if (Test-Path (Join-Path $BACKEND_DIR ".env")) {
        Get-Content (Join-Path $BACKEND_DIR ".env") | ForEach-Object {
            $line = $_.Trim()
            # 跳过注释行和空行
            if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
                return
            }
            # 导出有效的环境变量
            if ($line -match '^[A-Za-z_][A-Za-z0-9_]*=') {
                $k, $v = $line -split '=', 2
                Set-Item -Path Env:$k -Value $v
            }
        }
    }
}

# 设置默认端口和端口范围
function Set-BackendPort {
    # 缺省后端端口号是10000，允许的动态范围是10000-10099
    $BACKEND_DEFAULT_PORT = 10000
    $BACKEND_PORT_RANGE = "10000-10099"

    # 从.env文件读取端口配置
    if (Test-Path (Join-Path $PROJECT_ROOT ".env")) {
        $envContent = Get-Content (Join-Path $PROJECT_ROOT ".env")
        
        # 读取BACKEND_PORT
        $backendPortLine = $envContent | Where-Object { $_ -match '^[\s]*BACKEND_PORT=' }
        if ($backendPortLine) {
            $BACKEND_PORT = $backendPortLine -replace '^[\s]*BACKEND_PORT=', '' -replace '\s+$', ''
        } else {
            $BACKEND_PORT = $BACKEND_DEFAULT_PORT
        }
        
        # 读取BACKEND_PORT_RANGE
        $backendPortRangeLine = $envContent | Where-Object { $_ -match '^[\s]*BACKEND_PORT_RANGE=' }
        if ($backendPortRangeLine) {
            $BACKEND_PORT_RANGE = $backendPortRangeLine -replace '^[\s]*BACKEND_PORT_RANGE=', '' -replace '\s+$', ''
        }
    } else {
        $BACKEND_PORT = $BACKEND_DEFAULT_PORT
    }

    # 提取端口范围的起始和结束值
    $BACKEND_PORT_START, $BACKEND_PORT_END = $BACKEND_PORT_RANGE -split '-'

    # 检查端口是否被占用的函数
    function Is-PortOccupied {
        param([int]$Port)
        $inUse = netstat -ano | Select-String ":$Port " | Where-Object { $_.Line -match 'LISTENING' }
        return $inUse -ne $null
    }

    # 检查端口是否为本应用占用的函数
    function Is-AppPort {
        param([int]$Port)
        $result = netstat -ano | Select-String ":$Port " | Where-Object { $_.Line -match 'LISTENING' }
        if ($result) {
            $pid = $result.Line.Trim() -split '\s+' | Select-Object -Last 1
            if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
                $process = Get-Process -Id $pid
                if ($process.Path -like "*node.exe" -or $process.Path -like "*npm*" -or $process.Path -like "*yarn*" -or $process.Path -like "*pnpm*") {
                    $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $pid").CommandLine
                    if ($cmdLine -match "$BACKEND_DIR" -or $cmdLine -match "node.*$Port" -or $cmdLine -match "npm.*run.*dev") {
                        return $true
                    }
                }
            }
        }
        return $false
    }

    # 查找可用端口的函数
    function Find-AvailablePort {
        param([int]$Start, [int]$End, [int]$Current)
        
        # 先检查当前端口是否可用或为本应用占用
        if (-not (Is-PortOccupied $Current) -or (Is-AppPort $Current)) {
            return $Current
        }
        
        # 从当前端口开始查找可用端口
        for ($port = $Current; $port -le $End; $port++) {
            if (-not (Is-PortOccupied $port)) {
                return $port
            }
        }
        
        # 如果从当前端口到结束都没有可用端口，从起始端口到当前端口前一个查找
        for ($port = $Start; $port -lt $Current; $port++) {
            if (-not (Is-PortOccupied $port)) {
                return $port
            }
        }
        
        # 没有可用端口
        return $null
    }

    # 确保端口可用
    $availablePort = Find-AvailablePort $BACKEND_PORT_START $BACKEND_PORT_END $BACKEND_PORT
    if (-not $availablePort) {
        Print-Message $RED "错误: 无法在端口范围 $BACKEND_PORT_RANGE 内找到可用端口"
        exit 1
    }

    $Env:BACKEND_PORT = $availablePort
    $Env:PORT = $availablePort
    return $availablePort
}

# 检查后端服务是否运行
function Is-Running {
    if (Test-Path $PID_FILE) {
        $pid = Get-Content $PID_FILE
        if (Get-Process -Id $pid -ErrorAction SilentlyContinue) {
            return $true
        } else {
            Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    return $false
}

# 检查端口是否被占用
function Check-Port {
    param([int]$Port)
    $inUse = netstat -ano | Select-String ":$Port " | Where-Object { $_.Line -match 'LISTENING' }
    return $inUse -ne $null
}

# 获取占用指定端口的进程ID
function Get-PidByPort {
    param([int]$Port)
    $result = netstat -ano | Select-String ":$Port " | Where-Object { $_.Line -match 'LISTENING' }
    if ($result) {
        $parts = $result.Line.Trim() -split '\s+'
        return $parts[-1]
    }
    return $null
}

# 启动后端服务（开发模式）
function Start-Backend {
    if (Is-Running) {
        $pid = Get-Content $PID_FILE
        Print-Message $YELLOW "后端服务已在运行中 (PID: $pid)"
        return
    }
    
    $BACKEND_PORT = Set-BackendPort
    
    # 检查端口是否被占用
    if (Check-Port $BACKEND_PORT) {
        Print-Message $RED "错误: 端口 $BACKEND_PORT 已被占用"
        Print-Message $YELLOW "请使用以下命令查看占用进程: netstat -ano | findstr :$BACKEND_PORT"
        return
    }
    
    Print-Message $BLUE "启动后端服务..."
    
    # 确保在后端目录
    Set-Location $BACKEND_DIR
    
    # 检查依赖
    if (-not (Test-Path (Join-Path $BACKEND_DIR "node_modules"))) {
        Print-Message $YELLOW "安装后端依赖..."
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            pnpm install
            if ($LASTEXITCODE -ne 0) {
                Print-Message $RED "错误: 后端依赖安装失败"
                return
            }
        } else {
            npm install
            if ($LASTEXITCODE -ne 0) {
                Print-Message $RED "错误: 后端依赖安装失败"
                return
            }
        }
    }
    
    Ensure-LogDir
    
    # 启动后端开发服务器
    Print-Message $BLUE "DEBUG: 计划使用端口 BACKEND_PORT=$BACKEND_PORT"
    
    $startArgs = @(
        "run", "dev"
    )
    
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $process = Start-Process -FilePath pnpm -ArgumentList $startArgs -WorkingDirectory $BACKEND_DIR -PassThru -RedirectStandardOutput $LOG_FILE -RedirectStandardError $LOG_FILE -WindowStyle Hidden
    } else {
        $process = Start-Process -FilePath npm -ArgumentList $startArgs -WorkingDirectory $BACKEND_DIR -PassThru -RedirectStandardOutput $LOG_FILE -RedirectStandardError $LOG_FILE -WindowStyle Hidden
    }
    
    # 保存PID
    $process.Id | Set-Content $PID_FILE
    
    # 等待服务启动
    Start-Sleep -Seconds 5
    
    if (Is-Running) {
        Print-Message $GREEN "✓ 后端服务启动成功 (PID: $($process.Id))"
        Print-Message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        
        # 检查健康状态
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            Start-Sleep -Seconds 2
            try {
                curl -s "http://localhost:$BACKEND_PORT/health" | Out-Null
                Print-Message $GREEN "✓ 后端服务健康检查通过"
            } catch {
                Print-Message $YELLOW "⚠ 后端服务启动但健康检查失败"
            }
        }
        return
    } else {
        Print-Message $RED "✗ 后端服务启动失败"
        Print-Message $YELLOW "请查看日志: $LOG_FILE"
    }
}

# 启动后端服务（生产模式）
function Start-BackendProd {
    if (Is-Running) {
        $pid = Get-Content $PID_FILE
        Print-Message $YELLOW "后端服务已在运行中 (PID: $pid)"
        return
    }
    
    $BACKEND_PORT = Set-BackendPort
    
    # 检查端口是否被占用
    if (Check-Port $BACKEND_PORT) {
        Print-Message $RED "错误: 端口 $BACKEND_PORT 已被占用"
        Print-Message $YELLOW "请使用以下命令查看占用进程: netstat -ano | findstr :$BACKEND_PORT"
        return
    }
    
    Print-Message $BLUE "以生产模式启动后端服务..."
    
    # 确保在后端目录
    Set-Location $BACKEND_DIR
    
    # 检查依赖
    if (-not (Test-Path (Join-Path $BACKEND_DIR "node_modules"))) {
        Print-Message $YELLOW "安装后端依赖..."
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            pnpm install
            if ($LASTEXITCODE -ne 0) {
                Print-Message $RED "错误: 后端依赖安装失败"
                return
            }
        } else {
            npm install
            if ($LASTEXITCODE -ne 0) {
                Print-Message $RED "错误: 后端依赖安装失败"
                return
            }
        }
    }
    
    Ensure-LogDir
    
    # 构建项目
    Print-Message $BLUE "构建后端项目..."
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        pnpm run build
        if ($LASTEXITCODE -ne 0) {
            Print-Message $RED "错误: 后端构建失败"
            return
        }
    } else {
        npm run build
        if ($LASTEXITCODE -ne 0) {
            Print-Message $RED "错误: 后端构建失败"
            return
        }
    }
    
    # 设置生产环境变量
    $Env:NODE_ENV = "production"
    
    # 启动生产服务
    $startArgs = @(
        "run", "start"
    )
    
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $process = Start-Process -FilePath pnpm -ArgumentList $startArgs -WorkingDirectory $BACKEND_DIR -PassThru -RedirectStandardOutput $LOG_FILE -RedirectStandardError $LOG_FILE -WindowStyle Hidden
    } else {
        $process = Start-Process -FilePath npm -ArgumentList $startArgs -WorkingDirectory $BACKEND_DIR -PassThru -RedirectStandardOutput $LOG_FILE -RedirectStandardError $LOG_FILE -WindowStyle Hidden
    }
    
    # 保存PID
    $process.Id | Set-Content $PID_FILE
    
    # 等待服务启动
    Start-Sleep -Seconds 5
    
    if (Is-Running) {
        Print-Message $GREEN "✓ 后端服务(生产)启动成功 (PID: $($process.Id))"
        Print-Message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        
        # 检查健康状态
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            Start-Sleep -Seconds 2
            try {
                curl -s "http://localhost:$BACKEND_PORT/health" | Out-Null
                Print-Message $GREEN "✓ 后端服务健康检查通过"
            } catch {
                Print-Message $YELLOW "⚠ 后端服务启动但健康检查失败"
            }
        }
        return
    } else {
        Print-Message $RED "✗ 后端服务(生产)启动失败"
        Print-Message $YELLOW "请查看日志: $LOG_FILE"
    }
}

# 停止后端服务
function Stop-Backend {
    $BACKEND_PORT = Set-BackendPort
    
    if (-not (Is-Running)) {
        # 即使没有PID文件，也尝试根据端口清理残留进程
        if (Check-Port $BACKEND_PORT) {
            Print-Message $YELLOW "检测到端口 $BACKEND_PORT 有进程监听，尝试清理..."
            $portPid = Get-PidByPort $BACKEND_PORT
            if ($portPid) {
                Print-Message $YELLOW "清理残留的端口监听进程..."
                Stop-Process -Id $portPid -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
            if (Check-Port $BACKEND_PORT) {
                Print-Message $RED "✗ 警告: 端口 $BACKEND_PORT 仍被占用"
                $remainingPids = Get-PidByPort $BACKEND_PORT
                if ($remainingPids) {
                    Print-Message $YELLOW "占用端口的进程: $remainingPids"
                }
                return
            } else {
                Print-Message $GREEN "✓ 已清理端口占用，后端服务未运行"
                return
            }
        }
        Print-Message $YELLOW "后端服务未运行"
        return
    }
    
    $pid = Get-Content $PID_FILE
    Print-Message $BLUE "停止后端服务 (PID: $pid)..."
    
    # 尝试优雅停止主进程
    Stop-Process -Id $pid -ErrorAction SilentlyContinue
    
    # 等待进程结束
    $count = 0
    while (Get-Process -Id $pid -ErrorAction SilentlyContinue -and $count -lt 15) {
        Start-Sleep -Seconds 1
        $count++
    }
    
    # 如果主进程仍在运行，强制杀死
    if (Get-Process -Id $pid -ErrorAction SilentlyContinue) {
        Print-Message $YELLOW "强制停止后端服务..."
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
    
    # 清理端口占用
    $portPid = Get-PidByPort $BACKEND_PORT
    if ($portPid) {
        Print-Message $YELLOW "清理本项目的端口监听进程..."
        Stop-Process -Id $portPid -Force -ErrorAction SilentlyContinue
    }
    
    Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    
    # 验证端口是否已释放
    Start-Sleep -Seconds 2
    if (Check-Port $BACKEND_PORT) {
        Print-Message $RED "✗ 警告: 端口 $BACKEND_PORT 仍被占用"
        $remainingPids = Get-PidByPort $BACKEND_PORT
        if ($remainingPids) {
            Print-Message $YELLOW "占用端口的进程详情:"
            Get-Process -Id $remainingPids -ErrorAction SilentlyContinue | ForEach-Object {
                Print-Message $YELLOW "  $($_.Id) $($_.ProcessName)"
            }
            Print-Message $YELLOW "提示: 如果这些进程不属于本项目，请手动处理"
        }
    } else {
        Print-Message $GREEN "✓ 后端服务已完全停止"
    }
}

# 重启后端服务
function Restart-Backend {
    Print-Message $BLUE "重启后端服务..."
    Stop-Backend
    Start-Sleep -Seconds 3
    Start-Backend
}

# 显示后端服务状态
function Status-Backend {
    $BACKEND_PORT = Set-BackendPort
    
    if (Is-Running) {
        $pid = Get-Content $PID_FILE
        Print-Message $GREEN "✓ 后端服务正在运行 (PID: $pid)"
        Print-Message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        
        # 检查服务是否可访问
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            Print-Message $BLUE "检查服务可访问性..."
            try {
                curl -s "http://localhost:$BACKEND_PORT/health" | Out-Null
                Print-Message $GREEN "✓ 后端服务健康"
            } catch {
                Print-Message $YELLOW "⚠ 后端服务进程存在但API不可访问"
            }
        }
    } else {
        # 若无PID但端口有监听，提示服务可能在运行
        if (Check-Port $BACKEND_PORT) {
            Print-Message $YELLOW "⚠ 未发现PID文件，但检测到端口 $BACKEND_PORT 有服务在运行"
            Print-Message $BLUE "API地址: http://localhost:$BACKEND_PORT"
        } else {
            Print-Message $RED "✗ 后端服务未运行"
        }
    }
}

# 显示后端服务日志
function Show-Logs {
    if (Test-Path $LOG_FILE) {
        Print-Message $BLUE "后端服务日志 (最后50行):"
        Get-Content $LOG_FILE -Tail 50
    } else {
        Print-Message $YELLOW "日志文件不存在: $LOG_FILE"
    }
}

# 运行后端测试
function Run-Tests {
    Print-Message $BLUE "运行后端测试..."
    
    # 确保在后端目录
    Set-Location $BACKEND_DIR
    
    # 检查是否有测试脚本
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        if (pnpm run | Select-String -Pattern "test") {
            pnpm test
        } else {
            Print-Message $YELLOW "未找到测试脚本"
        }
    } else {
        if (npm run | Select-String -Pattern "test") {
            npm test
        } else {
            Print-Message $YELLOW "未找到测试脚本"
        }
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host "后端Node服务管理脚本"
    Write-Host ""
    Write-Host "使用方法: $($MyInvocation.MyCommand.Name) {start|start_prod|stop|restart|status|logs|test}"
    Write-Host ""
    Write-Host "命令说明:"
    Write-Host "  start     - 启动后端服务(开发模式)"
    Write-Host "  start_prod - 启动后端服务(生产模式)"
    Write-Host "  stop      - 停止后端服务"
    Write-Host "  restart   - 重启后端服务"
    Write-Host "  status    - 查看后端服务状态"
    Write-Host "  logs      - 查看后端服务日志"
    Write-Host "  test      - 运行后端测试"
    Write-Host "  help      - 显示帮助信息"
    Write-Host ""
    $BACKEND_PORT = Set-BackendPort
    Write-Host "API地址: http://localhost:$BACKEND_PORT"
}

# 主函数
switch ($cmd) {
    "start" {
        Start-Backend
    }
    "start_prod" {
        Start-BackendProd
    }
    "stop" {
        Stop-Backend
    }
    "restart" {
        Restart-Backend
    }
    "status" {
        Status-Backend
    }
    "logs" {
        Show-Logs
    }
    "test" {
        Run-Tests
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
