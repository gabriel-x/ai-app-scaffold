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
        $netstatOutput = netstat -ano | findstr :$Port | findstr LISTENING 2>&1
    } catch {
    }
    return [bool]$netstatOutput
}

# Get listening process IDs on a port
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

# Filter backend node processes on a port
function Get-BackendAppPids-OnPort {
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
                    $cmdLine -like "*$BACKEND_DIR*" -or
                    $cmdLine -match "server.ts" -or
                    $cmdLine -match "dist\\server.js" -or
                    $cmdLine -match "dist/server.js"
                )) {
                    $result += [int]$procId
                }
            }
        } catch {
        }
    }
    return $result
}

# Start backend service
function Start-Backend {
    # Load environment variables
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $BACKEND_DIR ".env")
    
    # Set default port and port range
    $BACKEND_DEFAULT_PORT = 10000
    $BACKEND_PORT_RANGE = $Env:BACKEND_PORT_RANGE
    if (-not $BACKEND_PORT_RANGE) {
        $BACKEND_PORT_RANGE = "10000-10099"
    }
    
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
    $Env:BACKEND_PORT = $BACKEND_PORT
    $Env:PORT = $BACKEND_PORT
    
    # Check if service is already running
    $isRunning, $runningProcessId = Is-Running
    if ($isRunning) {
        Print-Message "Yellow" "Backend service is already running (PID: $runningProcessId)"
        return 0
    }
    
    # Ensure dependencies are installed
    $nodeModulesPath = Join-Path $BACKEND_DIR "node_modules"
    if (-not (Test-Path $nodeModulesPath)) {
        Print-Message "Yellow" "Installing backend dependencies in $BACKEND_DIR..."
        try {
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                Push-Location $BACKEND_DIR
                npm install
                Pop-Location
            } else {
                Print-Message "Red" "[ERROR] npm not found in PATH (for install)"
                return 1
            }
        } catch {
            Print-Message "Red" "[ERROR] Failed to install backend dependencies: $($_.Exception.Message)"
            return 1
        }
    }
    
    Ensure-LogDir
    
    Print-Message "Blue" "Starting backend service..."
    Print-Message "Blue" "Using port: $BACKEND_PORT"
    
    $envCmd = "`$env:BACKEND_PORT=$BACKEND_PORT; `$env:PORT=$BACKEND_PORT"
    $startCmd = ""
    $distEntry = Join-Path $BACKEND_DIR "dist/server.js"
    if (Test-Path $distEntry) {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            $startCmd = "npm run start"
        } else {
            Print-Message "Red" "[ERROR] npm not found in PATH"
            return 1
        }
    } else {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            $startCmd = "npm run dev"
        } else {
            Print-Message "Red" "[ERROR] npm not found in PATH"
            return 1
        }
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
    
    # Find backend node process
    $nodeProcessId = 0
    
    # First try to find processes listening on BACKEND_PORT and belonging to backend
    $backendPids = Get-BackendAppPids-OnPort -Port $BACKEND_PORT
    if ($backendPids -and $backendPids.Count -gt 0) {
        $nodeProcessId = $backendPids[0]
    }
    
    # If not found, try to find child process via WMIC
    if (-not $nodeProcessId) {
        try {
            $candidate = Get-WmiObject Win32_Process | Where-Object {
                $_.ParentProcessId -eq $psProcessId -and $_.CommandLine -match "node"
            } | Select-Object -First 1
            if ($candidate) {
                $nodeProcessId = $candidate.ProcessId
            }
        } catch {
        }
    }
    
    # If still not found, try to find backend-related node processes
    if (-not $nodeProcessId) {
        try {
            $nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
            if ($nodeProcesses) {
                foreach ($nodeProc in $nodeProcesses) {
                    try {
                        $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId=$($nodeProc.Id)" 2>$null).CommandLine
                        if ($cmdLine -and (
                            $cmdLine -like "*$BACKEND_DIR*" -or
                            $cmdLine -match "server.ts" -or
                            $cmdLine -match "dist\\server.js"
                        )) {
                            $nodeProcessId = $nodeProc.Id
                            break
                        }
                    } catch {
                    }
                }
            }
        } catch {
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
        
        Print-Message "Green" "[OK] Backend service process detected (PID: $nodeProcessId)"
        Print-Message "Blue" "Access address: http://localhost:$actualPort"
        
        Print-Message "Blue" "Checking service accessibility..."
        $portOk = $false
        $healthOk = $false
        $statusCode = 0
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Seconds 1
            $portOk = Is-Service-Accessible $actualPort
            if ($portOk) {
                try {
                    $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$actualPort/health?service_check=backend" -TimeoutSec 5
                    $statusCode = [int]$resp.StatusCode
                    if ($statusCode -ge 200 -and $statusCode -lt 400) {
                        $healthOk = $true
                        break
                    }
                } catch {
                }
            }
        }
        if ($portOk -and $healthOk) {
            if ($statusCode -eq 200) {
                Print-Message "Green" "[OK] Backend service is accessible and healthy (HTTP 200)"
            } else {
                Print-Message "Green" "[OK] Backend service is accessible (HTTP $statusCode)"
            }
            return 0
        }
        Print-Message "Red" "[ERROR] Backend service failed health checks"
        if ($statusCode -ne 0) {
            Print-Message "Yellow" "Last health check HTTP status: $statusCode"
        }
        if (Test-Path $LOG_FILE) {
            Print-Message "Blue" "Recent backend logs:"
            Get-Content $LOG_FILE -Tail 30
        } else {
            Print-Message "Yellow" "Log file does not exist: $LOG_FILE"
        }
        Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
        return 1
    } else {
        Print-Message "Red" "[ERROR] Failed to start backend service"
        Print-Message "Yellow" "Please check logs: $LOG_FILE"
        return 1
    }
}

# Stop backend service
function Stop-Backend {
    # Load environment variables to determine port
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $BACKEND_DIR ".env")
    $BACKEND_PORT = $Env:BACKEND_PORT -as [int]
    if (-not $BACKEND_PORT) {
        $BACKEND_PORT = 10000
    }
    
    $isRunning, $processId = Is-Running
    if ($isRunning) {
        Print-Message "Blue" "Stopping backend service (PID: $processId)..."
        try {
            $process = Get-Process -Id $processId -ErrorAction Stop
            $process.Kill()
            $process.WaitForExit()
        } catch {
            Print-Message "Red" "Error stopping process: $_.Exception.Message"
        }
        Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    } else {
        Print-Message "Yellow" "Backend service is not running"
        Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    }
    
    Start-Sleep -Seconds 2
    if (Is-Service-Accessible $BACKEND_PORT) {
        $appPids = Get-BackendAppPids-OnPort -Port $BACKEND_PORT
        if ($appPids.Count -gt 0) {
            Print-Message "Yellow" "Detected project-related processes on port $BACKEND_PORT. Cleaning up..."
            foreach ($procId in $appPids) {
                try {
                    $p = Get-Process -Id $procId -ErrorAction Stop
                    $p.Kill()
                    $p.WaitForExit()
                } catch {
                }
            }
            Start-Sleep -Seconds 2
        }
    }
    
    if (Is-Service-Accessible $BACKEND_PORT) {
        Print-Message "Red" "[WARN] Port $BACKEND_PORT is still in use after cleanup"
        return 1
    } else {
        Print-Message "Green" "[OK] Backend service has been stopped and port released"
        return 0
    }
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
        # If no PID but port is listening, treat as running service on configured port
        if (Is-Service-Accessible $BACKEND_PORT) {
            Print-Message "Yellow" "[WARN] No PID file, but a service is listening on port $BACKEND_PORT"
            Print-Message "Blue" "Access address: http://localhost:$BACKEND_PORT"
            return 0
        }
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
