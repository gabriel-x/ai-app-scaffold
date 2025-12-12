# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia
Param([string]$cmd = "help")

Write-Host "Backend Python Service Manager"
Write-Host "Command: $cmd"

# Script paths and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend-python"
$PID_FILE = Join-Path $PROJECT_ROOT ".python.pid"
$LOG_FILE = Join-Path $BACKEND_DIR "logs\backend.log"

# Virtual environment configuration
$VENV = Join-Path $BACKEND_DIR "venv"

# Improved Python detection logic with better error handling
function Find-Python {
    # First try to use the python command (most common)
    try {
        $pythonCmd = Get-Command python -ErrorAction Stop
        return $pythonCmd.Source
    } catch {
        # If python command fails, try python3
        try {
            $python3Cmd = Get-Command python3 -ErrorAction Stop
            return $python3Cmd.Source
        } catch {
            # If both fail, try to find Python in common locations
            # Check common Python installation paths
            $commonPaths = @(
                "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
                "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
                "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
                "C:\Program Files\Python310\python.exe",
                "C:\Program Files\Python311\python.exe",
                "C:\Program Files\Python312\python.exe",
                "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\python.exe",
                "C:\Python310\python.exe",
                "C:\Python311\python.exe",
                "C:\Python312\python.exe"
            )
            
            foreach ($path in $commonPaths) {
                if (Test-Path $path) {
                    return $path
                }
            }
            
            # Check PATH environment variable for any Python executable
            $pathDirs = $env:PATH -split ';'
            foreach ($dir in $pathDirs) {
                $potentialPaths = @(
                    "$dir\python.exe",
                    "$dir\python3.exe"
                )
                
                foreach ($potentialPath in $potentialPaths) {
                    if (Test-Path $potentialPath) {
                        return $potentialPath
                    }
                }
            }
            
            return $null
        }
    }
}

# Find Python executable
$PYTHON_BIN = Find-Python

# Debug information
if ($PYTHON_BIN) {
    Write-Host "Found Python at: $PYTHON_BIN"
    try {
        $pythonVersion = & $PYTHON_BIN --version 2>&1
        Write-Host "Python version: $pythonVersion"
    } catch {
        Write-Host "Could not determine Python version."
    }
} else {
    Write-Host "Warning: Could not find Python executable through standard methods."
}

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
            
            # For Uvicorn with reloader, find the actual server child process
            try {
                $childProcesses = Get-WmiObject Win32_Process -Filter "ParentProcessId=$processId" 2>$null
                if ($childProcesses) {
                    foreach ($childProc in $childProcesses) {
                        if ($childProc.CommandLine -match "uvicorn" -and $childProc.CommandLine -notmatch "reloader") {
                            return $true, $childProc.ProcessId
                        }
                    }
                }
            } catch {
                # If we can't find child processes, return the parent
                return $true, $processId
            }
            
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
    # Check if Python is available
    if (-not $PYTHON_BIN) {
        Print-Message "Red" "[ERROR] Python interpreter not found. Please install Python first."
        return 1
    }
    
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
    
    # Check if virtual environment exists, create if not
    $pythonExePath = Join-Path (Join-Path $VENV "Scripts") "python.exe"
    if (-not (Test-Path $pythonExePath)) {
        Print-Message "Blue" "Creating virtual environment..."
        
        # Use a more reliable approach to execute Python commands
        $venvCreationResult = & $PYTHON_BIN -m venv $VENV 2>&1
        if ($LASTEXITCODE -ne 0) {
            Print-Message "Red" "[ERROR] Failed to create virtual environment: $venvCreationResult"
            return 1
        }
        
        # Check if virtual environment was actually created
        if (-not (Test-Path $pythonExePath)) {
            Print-Message "Red" "[ERROR] Virtual environment creation failed: $pythonExePath not found"
            return 1
        }
        
        # Upgrade pip
        Print-Message "Blue" "Upgrading pip..."
        $pipUpgradeResult = & "$VENV\Scripts\python.exe" -m pip install -U pip wheel setuptools --disable-pip-version-check -q 2>&1
        if ($LASTEXITCODE -ne 0) {
            Print-Message "Red" "[ERROR] Failed to upgrade pip: $pipUpgradeResult"
            return 1
        }
        
        # Install dependencies
        Print-Message "Blue" "Installing dependencies..."
        if (Test-Path (Join-Path $BACKEND_DIR "requirements.txt")) {
            $installResult = & "$VENV\Scripts\python.exe" -m pip install -r "requirements.txt" --disable-pip-version-check --no-input -q 2>&1
        } else {
            $installResult = & "$VENV\Scripts\python.exe" -m pip install fastapi uvicorn python-jose[cryptography] passlib[bcrypt] pydantic[email] pytest httpx --disable-pip-version-check --no-input -q 2>&1
        }
        
        if ($LASTEXITCODE -ne 0) {
            Print-Message "Red" "[ERROR] Failed to install dependencies: $installResult"
            return 1
        }
    }
    
    # Start Uvicorn service using Start-Process, this is the most reliable way
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "powershell.exe"
    $startInfo.Arguments = "-NoProfile -WindowStyle Hidden -Command cd '$BACKEND_DIR'; `$env:PORT=$BACKEND_PORT; `$env:BACKEND_PORT=$BACKEND_PORT; & '$VENV\Scripts\uvicorn.exe' app.main:app --port $BACKEND_PORT --host 127.0.0.1 --reload 2>&1 | Out-File '$LOG_FILE' -Append"
    $startInfo.WorkingDirectory = $BACKEND_DIR
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    
    # Get PowerShell process ID
    $psProcessId = $process.Id
    
    Print-Message "Blue" "Using environment: `$env:BACKEND_PORT=$BACKEND_PORT; `$env:PORT=$BACKEND_PORT"
    
    # Wait for service to start
    Print-Message "Blue" "Waiting for service to start..."
    Start-Sleep -Seconds 15
    
    # Find Python process in child processes
    $pythonProcessId = 0
    
    # First try to find all Python processes and check if they belong to this project
    try {
        # Get all Python processes
        $pythonProcesses = Get-Process -Name python -ErrorAction SilentlyContinue
        if ($pythonProcesses) {
            Print-Message "Blue" "Found Python processes: $($pythonProcesses.Count)"
            foreach ($pythonProc in $pythonProcesses) {
                Print-Message "Blue" "Checking Python PID: $($pythonProc.Id)"
                # Check process command line, confirm it's our project's service
                $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId=$($pythonProc.Id)" 2>$null).CommandLine
                if ($cmdLine -match "uvicorn" -and $cmdLine -match "app.main:app") {
                    $pythonProcessId = $pythonProc.Id
                    Print-Message "Blue" "Found matching Python process: $pythonProcessId"
                    break
                }
            }
        }
    } catch {
        Print-Message "Yellow" "Error finding Python processes: $_.Exception.Message"
    }
    
    # If not found, try to find by checking all listening ports for Python processes
    if (-not $pythonProcessId) {
        try {
            # Use netstat to find all LISTENING connections
            $netstatOutput = netstat -ano | findstr LISTENING 2>&1
            if ($netstatOutput) {
                Print-Message "Blue" "Checking all listening ports..."
                $netstatOutput | ForEach-Object {
                    $parts = $_ -split '\s+' | Where-Object { $_ }
                    if ($parts.Count -ge 5) {
                        $port = $parts[1] -replace '.*:', ''
                        $portPid = $parts[4]
                        
                        # Check if this PID is a Python process
                        try {
                            $proc = Get-Process -Id $portPid -ErrorAction Stop
                            if ($proc.Name -eq "python") {
                                Print-Message "Blue" "Found Python process $portPid listening on port $port"
                                $pythonProcessId = $portPid
                                $BACKEND_PORT = $port -as [int] # Update to actual port being used
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
    
    # If Python process is found, save PID
    if ($pythonProcessId) {
        $pythonProcessId | Set-Content $PID_FILE -Force
        
        Print-Message "Green" "[OK] Backend service started successfully (PID: $pythonProcessId)"
        Print-Message "Blue" "Access address: http://localhost:$BACKEND_PORT"
        
        # Check service accessibility
        Print-Message "Blue" "Checking service accessibility..."
        Start-Sleep -Seconds 5
        if (Is-Service-Accessible $BACKEND_PORT) {
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
    # Check if port 10001 is in use
    $portInUse = $false
    $portPid = 0
    try {
        $netstatOutput = netstat -ano | findstr :10001 | findstr LISTENING 2>&1
        if ($netstatOutput) {
            $portInUse = $true
            $parts = $netstatOutput -split '\s+' | Where-Object { $_ }
            if ($parts.Count -ge 5) {
                $portPid = $parts[4]
            }
            Print-Message "Blue" "Port 10001 is in use by PID: $portPid"
        }
    } catch {
        Print-Message "Yellow" "Error checking port 10001: $_.Exception.Message"
    }
    
    # Get all Python processes related to our project
    $pythonProcesses = @()
    
    # First, check all Python processes
    $allPythonProcesses = Get-Process -Name python -ErrorAction SilentlyContinue
    if ($allPythonProcesses) {
        Print-Message "Blue" "Found $($allPythonProcesses.Count) Python processes"
        
        foreach ($proc in $allPythonProcesses) {
            Print-Message "Blue" "Checking Python PID: $($proc.Id)"
            
            # Always add Python processes if port is in use
            if ($portInUse) {
                $pythonProcesses += $proc
                Print-Message "Blue" "Added process $($proc.Id) to stop list (port is in use)"
            } else {
                # Only check command line if port is not in use
                # Use alternative method to get command line
                $cmdLine = ""
                try {
                    # Method 1: WMIC
                    $cmdLine = wmic process where ProcessId=$($proc.Id) get CommandLine /format:list 2>&1 | findstr CommandLine | ForEach-Object { $_.Split('=')[1] } 2>$null
                    if (-not $cmdLine) {
                        # Method 2: Get-WmiObject (fallback)
                        $wmiProc = Get-WmiObject Win32_Process -Filter "ProcessId=$($proc.Id)" 2>$null
                        if ($wmiProc) {
                            $cmdLine = $wmiProc.CommandLine
                        }
                    }
                } catch {
                    Print-Message "Yellow" "Error getting command line for PID $($proc.Id): $_.Exception.Message"
                }
                
                Print-Message "Blue" "Command line: $cmdLine"
                
                # Check if this process is related to our project
                if ($cmdLine -match "uvicorn" -or $cmdLine -match "app.main:app" -or $cmdLine -match "spawn_main") {
                    $pythonProcesses += $proc
                    Print-Message "Blue" "Added process $($proc.Id) to stop list"
                }
            }
        }
    } else {
        Print-Message "Blue" "No Python processes found"
    }
    
    # Add the port PID directly if we found it and it's not already in our list
    if ($portInUse -and $portPid -gt 0) {
        $portProcFound = $false
        foreach ($proc in $pythonProcesses) {
            if ($proc.Id -eq $portPid) {
                $portProcFound = $true
                break
            }
        }
        if (-not $portProcFound) {
            # We can't get the process object, but we can still taskkill it
            $pythonProcesses += [PSCustomObject]@{ Id = $portPid }
            Print-Message "Blue" "Added port 10001 PID $portPid to stop list"
        }
    }
    
    if ($pythonProcesses.Count -eq 0 -and -not $portInUse) {
        Print-Message "Yellow" "Backend service is not running"
        return 0
    }
    
    # Get all Python processes related to our project and all processes listening on our port
    $processesToStop = @()
    
    # Add our identified Python processes
    foreach ($proc in $pythonProcesses) {
        $processesToStop += $proc.Id
    }
    
    # Add processes listening on port 10001
    try {
        $netstatOutput = netstat -ano | findstr :10001 | findstr LISTENING 2>&1
        if ($netstatOutput) {
            $parts = $netstatOutput -split '\s+' | Where-Object { $_ }
            if ($parts.Count -ge 5) {
                $portPid = $parts[4]
                if ($portPid -notin $processesToStop) {
                    $processesToStop += $portPid
                    Print-Message "Blue" "Added port 10001 PID $portPid to stop list"
                }
            }
        }
    } catch {
        Print-Message "Yellow" "Error checking port 10001 processes: $_.Exception.Message"
    }
    
    # Stop all processes in our stop list using taskkill (which works on all PIDs)
    if ($processesToStop.Count -gt 0) {
        Print-Message "Blue" "Stopping all identified processes: $($processesToStop -join ', ')"
        # Use stopPid instead of pid to avoid conflict with PowerShell built-in $pid
        foreach ($stopPid in $processesToStop) {
            Print-Message "Blue" "Stopping process (PID: $stopPid)..."
            # Use taskkill which can handle processes from all users
            taskkill /F /PID $stopPid 2>&1 | Out-Null
            Print-Message "Blue" "Taskkill result: $LASTEXITCODE"
        }
    }
    
    # Delete PID file
    Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
    
    # Verify all processes are stopped by checking the port
    Start-Sleep -Seconds 3
    $portStillInUse = $false
    try {
        $netstatOutput = netstat -ano | findstr :10001 | findstr LISTENING 2>&1
        if ($netstatOutput) {
            $portStillInUse = $true
            Print-Message "Yellow" "Port 10001 is still in use: $netstatOutput"
        }
    } catch {
        Print-Message "Yellow" "Error checking port 10001: $_.Exception.Message"
    }
    
    if (-not $portStillInUse) {
        Print-Message "Green" "[OK] Backend service has been stopped completely"
        return 0
    } else {
        Print-Message "Red" "[ERROR] Port 10001 is still in use after stopping processes"
        return 1
    }
}

# Show backend service status
function Status-Backend {
    # Load environment variables to get the correct port
    $PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
    $BACKEND_DIR = Join-Path $PROJECT_ROOT "backend-python"
    Load-Env (Join-Path $PROJECT_ROOT ".env")
    Load-Env (Join-Path $BACKEND_DIR ".env")
    
    # Set default port - should be backend port, not frontend port!
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
                            Write-Host "Found port $actualPort for PID $processId"
                            break
                        }
                    }
                }
            }
        } catch {
            Write-Host "Error finding port: $_.Exception.Message"
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