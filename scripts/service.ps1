# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia
Param([string]$cmd = "help")

# Script paths and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT = Split-Path -Parent $SCRIPT_DIR

# Module directories
$FE_DIR = Join-Path $ROOT "frontend"
$NODE_DIR = Join-Path $ROOT "backend-node"
$PY_DIR = Join-Path $ROOT "backend-python"

# PID file locations (consistent with module scripts)
$FE_PID_FILE = Join-Path $ROOT ".frontend.pid"
$NODE_PID_FILE = Join-Path $ROOT ".node.pid"
$PY_PID_FILE = Join-Path $ROOT ".python.pid"

# Management script paths for each module
$FE_SCRIPT = Join-Path $FE_DIR "scripts\client-manager.ps1"
$NODE_SCRIPT = Join-Path $NODE_DIR "scripts\server-manager.ps1"
$PY_SCRIPT = Join-Path $PY_DIR "scripts\server-manager.ps1"

# Check if service is running
function Is-Running {
    param([string]$PidFile)
    if (Test-Path $PidFile) {
        $processId = Get-Content $PidFile
        try {
            Get-Process -Id $processId -ErrorAction Stop | Out-Null
            return $true, $processId
        } catch {
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
            return $false, 0
        }
    }
    return $false, 0
}

# Print banner
function Print-Banner {
    param([string]$Message)
    Write-Host "======================================"
    Write-Host "$Message"
    Write-Host "======================================"
}

# Print colored message
function Print-Message {
    param(
        [string]$Color,
        [string]$Message
    )
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

# Execute script with error handling
function Execute-Script {
    param(
        [string]$ScriptPath,
        [string]$Command,
        [string]$ServiceName
    )
    
    Print-Message "Blue" "Executing $Command for $ServiceName..."
    
    # Reset console before executing child script
    [Console]::ResetColor()
    
    # Execute the script directly without output capturing which causes display issues
    & $ScriptPath $Command
    $exitCode = $LASTEXITCODE
    
    # Reset console again after script execution
    [Console]::ResetColor()
    
    if ($exitCode -eq 0) {
        Print-Message "Green" "$Command for $ServiceName completed successfully"
    } else {
        Print-Message "Red" "$Command for $ServiceName failed with exit code $exitCode"
    }
    
    # Ensure proper line termination
    Write-Host ""
    
    return $exitCode
}

# Start frontend service
function Start-Frontend {
    $isRunning, $processId = Is-Running $FE_PID_FILE
    if ($isRunning) {
        Print-Message "Yellow" "Frontend service is already running (PID: $processId)"
        return 0
    }
    
    return Execute-Script -ScriptPath $FE_SCRIPT -Command "start" -ServiceName "Frontend"
}

# Stop frontend service
function Stop-Frontend {
    return Execute-Script -ScriptPath $FE_SCRIPT -Command "stop" -ServiceName "Frontend"
}

# Check frontend service status
function Status-Frontend {
    Print-Banner "Frontend Service Status"
    return Execute-Script -ScriptPath $FE_SCRIPT -Command "status" -ServiceName "Frontend"
}

# Restart frontend service
function Restart-Frontend {
    Print-Banner "Restart Frontend Service"
    Stop-Frontend
    Start-Sleep -Seconds 3
    return Start-Frontend
}

# Start backend Node service
function Start-Node {
    $isRunning, $processId = Is-Running $NODE_PID_FILE
    if ($isRunning) {
        Print-Message "Yellow" "Backend Node service is already running (PID: $processId)"
        return 0
    }
    
    return Execute-Script -ScriptPath $NODE_SCRIPT -Command "start" -ServiceName "Backend Node"
}

# Stop backend Node service
function Stop-Node {
    return Execute-Script -ScriptPath $NODE_SCRIPT -Command "stop" -ServiceName "Backend Node"
}

# Check backend Node service status
function Status-Node {
    Print-Banner "Backend Node Service Status"
    return Execute-Script -ScriptPath $NODE_SCRIPT -Command "status" -ServiceName "Backend Node"
}

# Restart backend Node service
function Restart-Node {
    Print-Banner "Restart Backend Node Service"
    Stop-Node
    Start-Sleep -Seconds 3
    return Start-Node
}

# Start backend Python service
function Start-Python {
    $isRunning, $processId = Is-Running $PY_PID_FILE
    if ($isRunning) {
        Print-Message "Yellow" "Backend Python service is already running (PID: $processId)"
        return 0
    }
    
    return Execute-Script -ScriptPath $PY_SCRIPT -Command "start" -ServiceName "Backend Python"
}

# Stop backend Python service
function Stop-Python {
    return Execute-Script -ScriptPath $PY_SCRIPT -Command "stop" -ServiceName "Backend Python"
}

# Check backend Python service status
function Status-Python {
    Print-Banner "Backend Python Service Status"
    return Execute-Script -ScriptPath $PY_SCRIPT -Command "status" -ServiceName "Backend Python"
}

# Restart backend Python service
function Restart-Python {
    Print-Banner "Restart Backend Python Service"
    Stop-Python
    Start-Sleep -Seconds 3
    return Start-Python
}

# Start all services
function Start-All {
    Print-Banner "Start All Services"
    $exitCode1 = Start-Frontend
    Write-Host
    $exitCode2 = Start-Node
    Write-Host
    $exitCode3 = Start-Python
    
    return ($exitCode1 -or $exitCode2 -or $exitCode3)
}

# Stop all services
function Stop-All {
    Print-Banner "Stop All Services"
    $exitCode1 = Stop-Frontend
    Write-Host
    $exitCode2 = Stop-Node
    Write-Host
    $exitCode3 = Stop-Python
    
    return ($exitCode1 -or $exitCode2 -or $exitCode3)
}

# Restart all services
function Restart-All {
    Print-Banner "Restart All Services"
    $exitCode1 = Restart-Frontend
    Write-Host
    $exitCode2 = Restart-Node
    Write-Host
    $exitCode3 = Restart-Python
    
    return ($exitCode1 -or $exitCode2 -or $exitCode3)
}

# Check all services status
function Status-All {
    Print-Banner "Services Status"
    $exitCode1 = Status-Frontend
    Write-Host
    $exitCode2 = Status-Node
    Write-Host
    $exitCode3 = Status-Python
    
    return ($exitCode1 -or $exitCode2 -or $exitCode3)
}

# Show help information
function Show-Help {
    Print-Banner "Service Management Script"
    Write-Host ""
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) {start|stop|restart|status|start:frontend|stop:frontend|restart:frontend|status:frontend|start:node|stop:node|restart:node|status:node|start:python|stop:python|restart:python|status:python|help}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start               - Start all services"
    Write-Host "  stop                - Stop all services"
    Write-Host "  restart             - Restart all services"
    Write-Host "  status              - Check all services status"
    Write-Host "  start:frontend      - Start frontend service"
    Write-Host "  stop:frontend       - Stop frontend service"
    Write-Host "  restart:frontend    - Restart frontend service"
    Write-Host "  status:frontend     - Check frontend service status"
    Write-Host "  start:node          - Start backend Node service"
    Write-Host "  stop:node           - Stop backend Node service"
    Write-Host "  restart:node        - Restart backend Node service"
    Write-Host "  status:node         - Check backend Node service status"
    Write-Host "  start:python        - Start backend Python service"
    Write-Host "  stop:python         - Stop backend Python service"
    Write-Host "  restart:python      - Restart backend Python service"
    Write-Host "  status:python       - Check backend Python service status"
    Write-Host "  help                - Show help information"
    Write-Host ""
}

# Main function
try {
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
            Status-Python
        }
        "help" {
            Show-Help
        }
        default {
            Print-Message "Red" "Error: Unknown command '$cmd'"
            Write-Host ""
            Show-Help
        }
    }
} catch {
    Print-Message "Red" "Unexpected error occurred: $_.Exception.Message"
    exit 1
}