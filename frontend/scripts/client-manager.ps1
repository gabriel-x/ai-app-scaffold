# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia
Param([string]$cmd = "help")

Write-Host "Frontend Service Manager"
Write-Host "Command: $cmd"

# 脚本路径和项目根目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$FRONTEND_DIR = Join-Path $PROJECT_ROOT "frontend"
$PID_FILE = Join-Path $PROJECT_ROOT ".frontend.pid"
$LOG_FILE = Join-Path $FRONTEND_DIR "logs\frontend.log"

# 确保日志目录存在
function Ensure-LogDir {
    $logDir = Split-Path -Parent $LOG_FILE
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
}

# 检查前端服务是否运行
function Is-Running {
    if (Test-Path $PID_FILE) {
        $processId = Get-Content $PID_FILE
        try {
            $process = Get-Process -Id $processId -ErrorAction Stop
            return $true, $processId
        } catch {
            Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
            return $false, 0
        }
    }
    return $false, 0
}

# 加载环境变量
function Load-Env {
    param(
        [string]$EnvFile
    )
    if (Test-Path $EnvFile) {
        Get-Content $EnvFile | ForEach-Object {
            $line = $_.Trim()
            # 跳过注释行和空行
            if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
                return
            }
            # 跳过只包含空格和注释的行
            $strippedLine = $line -replace '\s+', ''
            if ($strippedLine.StartsWith('#') -or [string]::IsNullOrWhiteSpace($strippedLine)) {
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

# 打印带颜色的消息
function Print-Message {
    param(
        [string]$Color,
        [string]$Message
    )
    # 简化颜色输出，避免编码问题
    switch ($Color) {
        "Red" {
            Write-Host -ForegroundColor Red "$Message"
        }
        "Green" {
            Write-Host -ForegroundColor Green "$Message"
        }
        "Yellow" {
            Write-Host -ForegroundColor Yellow "$Message"
        }
        "Blue" {
            Write-Host -ForegroundColor Blue "$Message"
        }
        default {
            Write-Host "$Message"
        }
    }
}

# 检查服务是否可访问
function Is-Service-Accessible {
    param(
        [int]$Port
    )
    try {
        $netstatOutput = netstat -ano | findstr :$Port | findstr LISTENING 2>&1
        if ($netstatOutput) {
            return $true
        }
    } catch {
    }
    return $false
}

# 通过端口查找监听进程 PID 列表
function Get-Pids-ByPort {
    param(
        [int]$Port
    )
    $pids = @()
    try {
        $netstatOutput = netstat -ano | findstr :$Port 2>&1
        if ($netstatOutput) {
            $netstatOutput | ForEach-Object {
                if ($_ -match "LISTENING\s+(\d+)") {
                    $pids += [int]$matches[1]
                }
            }
        }
    } catch {
    }
    return $pids
}

# 过滤出本项目相关的进程 PID（根据命令行中的前端目录 / vite / node 关键字）
function Get-AppPids-OnPort {
    param(
        [int]$Port
    )
    $result = @()
    $pids = Get-Pids-ByPort -Port $Port
    if (-not $pids -or $pids.Count -eq 0) {
        return $result
    }
    foreach ($procId in $pids) {
        try {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$procId"
            if ($null -ne $proc) {
                $cmdLine = $proc.CommandLine
                if ($cmdLine -and (
                    $cmdLine -like "*$FRONTEND_DIR*" -or
                    $cmdLine -match "vite.*$Port" -or
                    $cmdLine -match "node.*$Port"
                )) {
                    $result += [int]$procId
                }
            }
        } catch {
        }
    }
    return $result
}

# 启动前端服务
function Start-Frontend {
    # 加载环境变量
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $FRONTEND_DIR ".env")
    
    # 设置默认端口和端口范围（与 Bash 脚本保持一致）
    $FRONTEND_DEFAULT_PORT = 10100
    $FRONTEND_PORT_RANGE = $Env:FRONTEND_PORT_RANGE
    if (-not $FRONTEND_PORT_RANGE) {
        $FRONTEND_PORT_RANGE = "10100-10199"
    }
    
    # 从环境变量读取端口配置
    $FRONTEND_PORT = $Env:FRONTEND_PORT -as [int]
    if (-not $FRONTEND_PORT) {
        $FRONTEND_PORT = $FRONTEND_DEFAULT_PORT
    }
    
    # 提取端口范围的起始和结束值
    $rangeParts = $FRONTEND_PORT_RANGE -split "-"
    $FRONTEND_PORT_START = [int]$rangeParts[0]
    $FRONTEND_PORT_END = [int]$rangeParts[1]
    
    # 检查端口是否被占用的函数
    function Is-Port-Occupied {
        param(
            [int]$port
        )
        try {
            $netstatOutput = netstat -ano | findstr :$port 2>&1
            if ($netstatOutput -and $netstatOutput -match "LISTENING") {
                return $true
            }
        } catch {
            # 忽略错误
        }
        return $false
    }
    
    # 查找可用端口的函数
    function Find-Available-Port {
        param(
            [int]$start,
            [int]$end,
            [int]$current
        )
        
        # 先检查当前端口是否可用
        if (-not (Is-Port-Occupied $current)) {
            return $current
        }
        
        # 从当前端口开始查找可用端口
        for ($port = $current; $port -le $end; $port++) {
            if (-not (Is-Port-Occupied $port)) {
                return $port
            }
        }
        
        # 如果从当前端口到结束都没有可用端口，从起始端口到当前端口前一个查找
        for ($port = $start; $port -lt $current; $port++) {
            if (-not (Is-Port-Occupied $port)) {
                return $port
            }
        }
        
        # 没有可用端口
        return $null
    }
    
    # 确保端口可用
    $availablePort = Find-Available-Port $FRONTEND_PORT_START $FRONTEND_PORT_END $FRONTEND_PORT
    if ($availablePort -eq $null) {
        Print-Message "Red" "错误: 无法在端口范围 $FRONTEND_PORT_RANGE 内找到可用端口"
        return 1
    }
    $FRONTEND_PORT = $availablePort
    $Env:FRONTEND_PORT = $FRONTEND_PORT
    $Env:PORT = $FRONTEND_PORT
    
    # 检查服务是否已运行
    $isRunning, $runningProcessId = Is-Running
    if ($isRunning) {
        Print-Message "Yellow" "Frontend service is already running (PID: $runningProcessId)"
        return 0
    }
    
    # 检查依赖是否已安装（不存在 node_modules 时自动安装）
    $nodeModulesPath = Join-Path $FRONTEND_DIR "node_modules"
    if (-not (Test-Path $nodeModulesPath)) {
        Print-Message "Yellow" "Installing frontend dependencies in $FRONTEND_DIR..."
        try {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Push-Location $FRONTEND_DIR
                pnpm install
                Pop-Location
            } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
                Push-Location $FRONTEND_DIR
                npm install
                Pop-Location
            } else {
                Print-Message "Red" "[ERROR] Neither pnpm nor npm found in PATH (for install)"
                return 1
            }
        } catch {
            Print-Message "Red" "[ERROR] Failed to install frontend dependencies: $($_.Exception.Message)"
            return 1
        }
    }
    
    Ensure-LogDir
    
    Print-Message "Blue" "Starting frontend service..."
    Print-Message "Blue" "Using port: $FRONTEND_PORT"
    
    # 生成启动命令
    $envCmd = "`$env:FRONTEND_PORT=$FRONTEND_PORT; `$env:PORT=$FRONTEND_PORT"
    $startCmd = ""
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $startCmd = "pnpm run dev --port $FRONTEND_PORT --strictPort"
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        $startCmd = "npm run dev -- --port $FRONTEND_PORT --strictPort"
    } else {
        Print-Message "Red" "[ERROR] Neither pnpm nor npm found in PATH"
        return 1
    }
    
    # 直接使用Start-Process启动node服务，这是最可靠的方式
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "powershell.exe"
    $startInfo.Arguments = "-NoProfile -WindowStyle Hidden -Command $envCmd; cd '$FRONTEND_DIR'; $startCmd 2>&1 | Out-File '$LOG_FILE' -Append"
    $startInfo.WorkingDirectory = $FRONTEND_DIR
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    
    # 获取PowerShell进程ID
    $psProcessId = $process.Id
    
    # 等待服务启动
    Print-Message "Blue" "Waiting for service to start..."
    Start-Sleep -Seconds 10
    
    # 查找子进程中的node进程
    $nodeProcessId = 0
    
    # 首先尝试直接通过端口查找PID，这是最可靠的方法
    try {
        # 使用netstat查找端口对应的PID
        $netstatOutput = netstat -ano | findstr :$FRONTEND_PORT 2>&1
        if ($netstatOutput) {
            # 从netstat输出中提取PID
            $netstatOutput | ForEach-Object {
                if ($_ -match "LISTENING\s+(\d+)") {
                    $nodeProcessId = $matches[1]
                }
            }
        }
    } catch {
        # 忽略错误，继续尝试其他方法
    }
    
    # 如果端口查找失败，尝试通过WMIC查找子进程
    if (-not $nodeProcessId) {
        try {
            $wmicOutput = wmic process where (ParentProcessId=$psProcessId) get ProcessId, CommandLine /format:list 2>&1
            $nodeProcessId = $wmicOutput | Where-Object { $_ -match "node" } | ForEach-Object {
                if ($_ -match "ProcessId=(\d+)") {
                    return $matches[1]
                }
            }
        } catch {
            # 忽略错误，继续执行
        }
    }
    
    # 如果WMIC失败，尝试另一种方法
    if (-not $nodeProcessId) {
        try {
            $nodeProcessId = Get-WmiObject Win32_Process | Where-Object {
                $_.ParentProcessId -eq $psProcessId -and $_.CommandLine -match "node"
            } | Select-Object -ExpandProperty ProcessId
        } catch {
            # 忽略错误，继续执行
        }
    }
    
    # 如果找到node进程，保存PID
    if ($nodeProcessId) {
        $nodeProcessId | Set-Content $PID_FILE -Force
        
        Print-Message "Green" "[OK] Frontend service started successfully (PID: $nodeProcessId)"
        Print-Message "Blue" "Access address: http://localhost:$FRONTEND_PORT"
        
        # 检查服务可访问性
        Print-Message "Blue" "Checking service accessibility..."
        Start-Sleep -Seconds 5
        if (Is-Service-Accessible $FRONTEND_PORT) {
            Print-Message "Green" "[OK] Frontend service is accessible"
        } else {
            Print-Message "Yellow" "[WARN] Frontend service started but temporarily inaccessible"
        }
        return 0
    } else {
        Print-Message "Red" "[ERROR] Failed to start frontend service"
        Print-Message "Yellow" "Please check logs: $LOG_FILE"
        return 1
    }
}

# 停止前端服务
function Stop-Frontend {
    $isRunning, $processId = Is-Running
    if (-not $isRunning) {
        # 即使未检测到运行中的 PID，也检查端口上是否有本项目残留进程
        Load-Env (Join-Path $PROJECT_ROOT ".env")
        Load-Env (Join-Path $FRONTEND_DIR ".env")
        $FRONTEND_PORT = $Env:FRONTEND_PORT -as [int]
        if (-not $FRONTEND_PORT) {
            $FRONTEND_PORT = 10100
        }
        $appPids = Get-AppPids-OnPort -Port $FRONTEND_PORT
        if ($appPids.Count -gt 0) {
            Print-Message "Yellow" "Detected processes on port $FRONTEND_PORT that appear to belong to this project. Attempting to clean up..."
            foreach ($procId in $appPids) {
                try {
                    $p = Get-Process -Id $procId -ErrorAction Stop
                    $p.Kill()
                    $p.WaitForExit()
                } catch {
                }
            }
            Start-Sleep -Seconds 2
            if (Is-Service-Accessible $FRONTEND_PORT) {
                Print-Message "Red" "[WARN] Port $FRONTEND_PORT is still in use after cleanup"
                return 1
            } else {
                Print-Message "Green" "[OK] Cleaned up leftover frontend processes. Service is not running."
                Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
                return 0
            }
        }
        Print-Message "Yellow" "Frontend service is not running"
        Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
        return 0
    }
    
    Print-Message "Blue" "Stopping frontend service (PID: $processId)..."
    
    try {
        $process = Get-Process -Id $processId -ErrorAction Stop
        $process.Kill()
        $process.WaitForExit()
    } catch {
        Print-Message "Red" "Error stopping process: $_.Exception.Message"
    }
    
    # 删除PID文件
    Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    
    Print-Message "Green" "[OK] Frontend service has been stopped"
    return 0
}

# 显示前端服务状态
function Status-Frontend {
    # 加载环境变量以获取正确的端口
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $FRONTEND_DIR ".env")
    
    # 设置默认端口
    $FRONTEND_PORT = $Env:FRONTEND_PORT -as [int]
    if (-not $FRONTEND_PORT) {
        $FRONTEND_PORT = 10100
    }
    
    $isRunning, $processId = Is-Running
    if ($isRunning) {
        Print-Message "Green" "[OK] Frontend service is running (PID: $processId)"
        Print-Message "Blue" "Access address: http://localhost:$FRONTEND_PORT"
        
        # 检查服务可访问性
        Print-Message "Blue" "Checking service accessibility..."
        if (Is-Service-Accessible $FRONTEND_PORT) {
            Print-Message "Green" "[OK] Frontend service is accessible"
        } else {
            Print-Message "Yellow" "[WARN] Frontend service process exists but page is inaccessible"
        }
        return 0
    } else {
        # 若无 PID 但端口有监听，提示服务可能由外部启动
        if (Is-Service-Accessible $FRONTEND_PORT) {
            Print-Message "Yellow" "[WARN] No PID file, but a service is listening on port $FRONTEND_PORT"
            Print-Message "Blue" "Access address: http://localhost:$FRONTEND_PORT"
            return 0
        }
        Print-Message "Red" "[ERROR] Frontend service is not running"
        return 1
    }
}

# 重启前端服务
function Restart-Frontend {
    Print-Message "Blue" "Restarting frontend service..."
    Stop-Frontend
    Start-Sleep -Seconds 3
    return Start-Frontend
}

# 显示前端服务日志
function Show-Logs {
    if (Test-Path $LOG_FILE) {
        Print-Message "Blue" "Frontend service logs (last 50 lines):"
        Get-Content $LOG_FILE -Tail 50
    } else {
        Print-Message "Yellow" "Log file does not exist: $LOG_FILE"
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host ""
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) {start|stop|restart|status|logs}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start   - Start frontend service"
    Write-Host "  stop    - Stop frontend service"
    Write-Host "  restart - Restart frontend service"
    Write-Host "  status  - Check frontend service status"
    Write-Host "  logs    - View frontend service logs"
    Write-Host "  help    - Show help information"
}

# 根据命令执行不同操作
$exitCode = 0
switch ($cmd) {
    "start" {
        $exitCode = Start-Frontend
    }
    "stop" {
        $exitCode = Stop-Frontend
    }
    "restart" {
        Restart-Frontend
        $exitCode = $LASTEXITCODE
    }
    "status" {
        $exitCode = Status-Frontend
    }
    "logs" {
        Show-Logs
        $exitCode = 0
    }
    "help" {
        Show-Help
        $exitCode = 0
    }
    default {
        Print-Message "Red" "Error: Unknown command $cmd"
        Show-Help
        $exitCode = 1
    }
}

# 确保脚本返回正确的退出码
exit $exitCode
