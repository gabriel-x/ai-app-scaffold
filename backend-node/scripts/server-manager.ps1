# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia
Param([string]$cmd = "help")

Write-Host "Backend Node Service Manager"
Write-Host "Command: $cmd"

# Script paths and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend-node"
$PID_FILE = Join-Path $PROJECT_ROOT ".node.pid"
$LOG_FILE = Join-Path $BACKEND_DIR "logs\backend.log"

# Ensure log directory exists
function Ensure-LogDir {
    $logDir = Split-Path -Parent $LOG_FILE
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
}

# Check if backend service is running
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

# Load environment variables
function Load-Env {
    param(
        [string]$EnvFile
    )
    if (Test-Path $EnvFile) {
        Get-Content $EnvFile | ForEach-Object {
            $line = $_.Trim()
            # Skip comment lines and empty lines
            if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
                return
            }
            # Skip lines that only contain spaces and comments
            $strippedLine = $line -replace '\s+', ''
            if ($strippedLine.StartsWith('#') -or [string]::IsNullOrWhiteSpace($strippedLine)) {
                return
            }
            # Export valid environment variables
            if ($line -match '^[A-Za-z_][A-Za-z0-9_]*=') {
                $k, $v = $line -split '=', 2
                Set-Item -Path Env:$k -Value $v
            }
        }
    }
}

# Print colored message
function Print-Message {
    param(
        [string]$Color,
        [string]$Message
    )
    # Simplify color output to avoid encoding issues
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

# Check if service is accessible
function Is-Service-Accessible {
    param(
        [int]$Port
    )
    try {
        # Use netstat to check if port is listening - more reliable than web requests
        $netstatOutput = netstat -ano | findstr :$Port | findstr LISTENING 2>&1
        return [bool]$netstatOutput
    } catch {
        return $false
    }
}

# Start backend service
function Start-Backend {
    # Load environment variables
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $BACKEND_DIR ".env")
    
    # Set default port and port range
    # Default backend port is 10000, allowed dynamic range is 10000-10099
    $BACKEND_DEFAULT_PORT = 10000
    $BACKEND_PORT_RANGE = "10000-10099"
    
    # Read port configuration from .env file
    $BACKEND_PORT = $Env:BACKEND_PORT -as [int]
    if (-not $BACKEND_PORT) {
        $BACKEND_PORT = $BACKEND_DEFAULT_PORT
    }
    
    # Extract port range start and end values
    $rangeParts = $BACKEND_PORT_RANGE -split "-"
    $BACKEND_PORT_START = [int]$rangeParts[0]
    $BACKEND_PORT_END = [int]$rangeParts[1]
    
    # Check if port is occupied function
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
            # Ignore errors
        }
        return $false
    }
    
    # Find available port function
    function Find-Available-Port {
        param(
            [int]$start,
            [int]$end,
            [int]$current
        )
        
        # First check if current port is available
        if (-not (Is-Port-Occupied $current)) {
            return $current
        }
        
        # Check ports from current to end
        for ($port = $current; $port -le $end; $port++) {
            if (-not (Is-Port-Occupied $port)) {
                return $port
            }
        }
        
        # If no available port from current to end, check from start to current-1
        for ($port = $start; $port -lt $current; $port++) {
            if (-not (Is-Port-Occupied $port)) {
                return $port
            }
        }
        
        # No available port found
        return $null
    }
    
    # Ensure port is available
    $availablePort = Find-Available-Port $BACKEND_PORT_START $BACKEND_PORT_END $BACKEND_PORT
    if ($availablePort -eq $null) {
        Print-Message "Red" "Error: Cannot find available port in range $BACKEND_PORT_RANGE"
        return 1
    }
    $BACKEND_PORT = $availablePort
    
    # Check if service is already running
    $isRunning, $runningProcessId = Is-Running
    if ($isRunning) {
        Print-Message "Yellow" "Backend service is already running (PID: $runningProcessId)"
        return 0
    }
    
    Ensure-LogDir
    
    Print-Message "Blue" "Starting backend service..."
    Print-Message "Blue" "Using port: $BACKEND_PORT"
    
    # Generate start command
    $envCmd = "`$env:BACKEND_PORT=$BACKEND_PORT; `$env:PORT=$BACKEND_PORT"
    $startCmd = ""
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $startCmd = "pnpm run dev"
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        $startCmd = "npm run dev"
    } else {
        Print-Message "Red" "[ERROR] Neither pnpm nor npm found in PATH"
        return 1
    }
    
    Print-Message "Blue" "Using environment: $envCmd"
    
    # Start node service using Start-Process, this is the most reliable way
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "powershell.exe"
    $startInfo.Arguments = "-NoProfile -WindowStyle Hidden -Command $envCmd; cd '$BACKEND_DIR'; $startCmd 2>&1 | Out-File '$LOG_FILE' -Append"
    $startInfo.WorkingDirectory = $BACKEND_DIR
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    
    # Get PowerShell process ID
    $psProcessId = $process.Id
    
    # Wait for service to start
    Print-Message "Blue" "Waiting for service to start..."
    Start-Sleep -Seconds 15
    
    # Find node process in child processes
    $nodeProcessId = 0
    
    # First try to find all node processes and check if they belong to this project
    try {
        # Get all node processes
        $nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
        if ($nodeProcesses) {
            Print-Message "Blue" "Found node processes: $($nodeProcesses.Count)"
            foreach ($nodeProc in $nodeProcesses) {
                Print-Message "Blue" "Checking node PID: $($nodeProc.Id)"
                # Check process command line, confirm it's our project's service
                $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId=$($nodeProc.Id)" 2>$null).CommandLine
                if ($cmdLine -match "server.ts" -or $cmdLine -match "dist\\server.js") {
                    $nodeProcessId = $nodeProc.Id
                    Print-Message "Blue" "Found matching node process: $nodeProcessId"
                    break
                }
            }
        }
    } catch {
        Print-Message "Yellow" "Error finding node processes: $_.Exception.Message"
    }
    
    # If not found, try to find by checking all listening ports for node processes
    if (-not $nodeProcessId) {
        try {
            # Use netstat to find all LISTENING connections
            $netstatOutput = netstat -ano | findstr LISTENING 2>&1
            if ($netstatOutput) {
                Print-Message "Blue" "Checking all listening ports..."
                $netstatOutput | ForEach-Object {
                    $parts = $_ -split '\s+' | Where-Object { $_ }
                    if ($parts.Count -ge 5) {
                        $port = $parts[1] -replace '.*:', ''
                        $processId = $parts[4]
                        
                        # Check if this PID is a node process
                        try {
                            $proc = Get-Process -Id $processId -ErrorAction Stop
                            if ($proc.Name -eq "node") {
                                Print-Message "Blue" "Found node process $processId listening on port $port"
                                $nodeProcessId = $processId
                                # Update to actual port being used
                                $BACKEND_PORT = $port -as [int]
                                break
                            }
                        } catch {
                            # Ignore non-existent processes
                        }
                    }
                }
            }
        } catch {
            Print-Message "Yellow" "Error checking listening ports: $_.Exception.Message"
        }
    }
    
    # If port lookup fails, try to find child process via WMIC
    if (-not $nodeProcessId) {
        try {
            $wmicOutput = wmic process where (ParentProcessId=$psProcessId) get ProcessId, CommandLine /format:list 2>&1
            $nodeProcessId = $wmicOutput | Where-Object { $_ -match "node" } | ForEach-Object {
                if ($_ -match "ProcessId=(\d+)") {
                    return $matches[1]
                }
            }
        } catch {
            # Ignore errors, continue execution
        }
    }
    
    # If WMIC fails, try another method
    if (-not $nodeProcessId) {
        try {
            $nodeProcessId = Get-WmiObject Win32_Process | Where-Object {
                $_.ParentProcessId -eq $psProcessId -and $_.CommandLine -match "node"
            } | Select-Object -ExpandProperty ProcessId
        } catch {
            # Ignore errors, continue execution
        }
    }
    
    # If node process is found, save PID
    if ($nodeProcessId) {
        $nodeProcessId | Set-Content $PID_FILE -Force
        
        # Find the actual port the service is listening on
        $actualPort = $BACKEND_PORT
        try {
            $netstatOutput = netstat -ano | findstr LISTENING 2>&1
            if ($netstatOutput) {
                foreach ($line in $netstatOutput) {
                    $parts = $line -split '\s+' | Where-Object { $_ }
                    if ($parts.Count -ge 5) {
                        $port = $parts[1] -replace '.*:', ''
                        $processId = $parts[4]
                        if ($processId -eq $nodeProcessId) {
                            $actualPort = [int]$port
                            Print-Message "Blue" "Found actual port $actualPort for PID $nodeProcessId"
                            break
                        }
                    }
                }
            }
        } catch {
            Print-Message "Yellow" "Error finding actual port: $_.Exception.Message"
        }
        
        Print-Message "Green" "[OK] Backend service started successfully (PID: $nodeProcessId)"
        Print-Message "Blue" "Access address: http://localhost:$actualPort"
        
        # Check service accessibility using actual port
        Print-Message "Blue" "Checking service accessibility..."
        Start-Sleep -Seconds 5
        if (Is-Service-Accessible $actualPort) {
            Print-Message "Green" "[OK] Backend service is accessible"
        } else {
            Print-Message "Yellow" "[WARN] Backend service started but temporarily inaccessible"
        }
        return 0
    } else {
        Print-Message "Red" "[ERROR] Failed to start backend service"
        Print-Message "Yellow" "Please check logs: $LOG_FILE"
        return 1
    }
}

# Stop backend service
function Stop-Backend {
    $isRunning, $processId = Is-Running
    if (-not $isRunning) {
        Print-Message "Yellow" "Backend service is not running"
        return 0
    }
    
    Print-Message "Blue" "Stopping backend service (PID: $processId)..."
    
    try {
        $process = Get-Process -Id $processId -ErrorAction Stop
        $process.Kill()
        $process.WaitForExit()
    } catch {
        Print-Message "Red" "Error stopping process: $_.Exception.Message"
    }
    
    # Delete PID file
    Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    
    Print-Message "Green" "[OK] Backend service has been stopped"
    return 0
}

# Show backend service status
function Status-Backend {
    # Load environment variables to get the correct port
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $BACKEND_DIR ".env")
    
    # Set default port
    $BACKEND_PORT = $Env:BACKEND_PORT -as [int]
    if (-not $BACKEND_PORT) {
        $BACKEND_PORT = 10000
    }
    
    $isRunning, $processId = Is-Running
    if ($isRunning) {
        Print-Message "Green" "[OK] Backend service is running (PID: $processId)"
        
        # Try to find the actual port the process is listening on
        $actualPort = $BACKEND_PORT
        try {
            # Get all listening ports and find the one matching our process ID
            $netstatOutput = netstat -ano | findstr LISTENING 2>&1
            if ($netstatOutput) {
                foreach ($line in $netstatOutput) {
                    $lineParts = $line -split '\s+' | Where-Object { $_ -ne '' }
                    if ($lineParts.Count -ge 5) {
                        $port = $lineParts[1] -replace '.*:', ''
                        $listeningPid = $lineParts[4]
                        if ([int]$listeningPid -eq $processId) {
                            $actualPort = [int]$port
                            Print-Message "Blue" "Found actual port $actualPort for PID $processId"
                            break
                        }
                    }
                }
            }
        } catch {
            Print-Message "Yellow" "Error finding actual port: $_.Exception.Message"
            # Ignore errors, use default port
        }
        
        Print-Message "Blue" "Access address: http://localhost:$actualPort"
        
        # Check service accessibility using actual port
        Print-Message "Blue" "Checking service accessibility..."
        if (Is-Service-Accessible $actualPort) {
            Print-Message "Green" "[OK] Backend service is accessible"
        } else {
            Print-Message "Yellow" "[WARN] Backend service process exists but page is inaccessible"
        }
        return 0
    } else {
        Print-Message "Red" "[ERROR] Backend service is not running"
        return 1
    }
}

# Restart backend service
function Restart-Backend {
    Print-Message "Blue" "Restarting backend service..."
    Stop-Backend
    Start-Sleep -Seconds 3
    Start-Backend
}

# Show backend service logs
function Show-Logs {
    if (Test-Path $LOG_FILE) {
        Print-Message "Blue" "Backend service logs (last 50 lines):"
        Get-Content $LOG_FILE -Tail 50
    } else {
        Print-Message "Yellow" "Log file does not exist: $LOG_FILE"
    }
}

# Show help information
function Show-Help {
    Write-Host ""
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) {start|stop|restart|status|logs}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start   - Start backend service"
    Write-Host "  stop    - Stop backend service"
    Write-Host "  restart - Restart backend service"
    Write-Host "  status  - Check backend service status"
    Write-Host "  logs    - View backend service logs"
    Write-Host "  help    - Show help information"
}

# Execute different operations based on command
$exitCode = 0
switch ($cmd) {
    "start" {
        $exitCode = Start-Backend
    }
    "stop" {
        $exitCode = Stop-Backend
    }
    "restart" {
        Restart-Backend
        $exitCode = $LASTEXITCODE
    }
    "status" {
        $exitCode = Status-Backend
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

# Ensure script returns correct exit code
exit $exitCode