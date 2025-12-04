# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param([string]$cmd = "help")

$ROOT = (Resolve-Path (Join-Path $PSScriptRoot ".."))
$PID_DIR = Join-Path $PSScriptRoot "pids"
New-Item -ItemType Directory -Force -Path $PID_DIR | Out-Null

$FE_DIR = Join-Path $ROOT "frontend"
$NODE_DIR = Join-Path $ROOT "backend-node"
$PY_DIR = Join-Path $ROOT "backend-python"

$FE_CMD = ${env:FE_CMD}; if (-not $FE_CMD) { $FE_CMD = "npm run dev" }
$NODE_CMD = ${env:NODE_CMD}; if (-not $NODE_CMD) { $NODE_CMD = "npm run dev" }
$PY_CMD = ${env:PY_CMD}; if (-not $PY_CMD) { $PY_CMD = "uvicorn app.main:app --port $env:PORT" }

function Start-Service($name, $dir, $cmd) {
  $pidFile = Join-Path $PID_DIR "$name.pid"
  if (Test-Path $pidFile) {
    $pid = Get-Content $pidFile
    try { if (Get-Process -Id $pid -ErrorAction Stop) { Write-Host "$name already running (pid $pid)"; return } } catch {}
  }
  Write-Host "starting $name..."
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = "powershell"
  $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"Set-Location '$dir'; $cmd\""
  $startInfo.UseShellExecute = $true
  $startInfo.CreateNoWindow = $true
  $proc = [System.Diagnostics.Process]::Start($startInfo)
  Set-Content -Path $pidFile -Value $proc.Id
  Write-Host "$name started (pid $($proc.Id))"
}

function Stop-Service($name) {
  $pidFile = Join-Path $PID_DIR "$name.pid"
  if (-not (Test-Path $pidFile)) { Write-Host "$name not running"; return }
  $pid = Get-Content $pidFile
  try {
    Write-Host "stopping $name (pid $pid)..."
    Stop-Process -Id $pid -ErrorAction SilentlyContinue
    Write-Host "$name stopped"
  } catch { Write-Host "$name not alive" }
  Remove-Item -Force $pidFile -ErrorAction SilentlyContinue
}

function Status-Service($name) {
  $pidFile = Join-Path $PID_DIR "$name.pid"
  if (Test-Path $pidFile) {
    $pid = Get-Content $pidFile
    try { if (Get-Process -Id $pid -ErrorAction Stop) { Write-Host "$name running (pid $pid)"; return } } catch {}
  }
  Write-Host "$name stopped"
}

function Restart-Service($name, $dir, $cmd) { Stop-Service $name; Start-Service $name $dir $cmd }

function Start-Frontend { Start-Service "frontend" $FE_DIR $FE_CMD }
function Stop-Frontend { Stop-Service "frontend" }
function Status-Frontend { Status-Service "frontend" }
function Restart-Frontend { Restart-Service "frontend" $FE_DIR $FE_CMD }

function Start-Node { Start-Service "node" $NODE_DIR $NODE_CMD }
function Stop-Node { Stop-Service "node" }
function Status-Node { Status-Service "node" }
function Restart-Node { Restart-Service "node" $NODE_DIR $NODE_CMD }

function Start-Python { Start-Service "python" $PY_DIR $PY_CMD }
function Stop-Python { Stop-Service "python" }
function Status-Python { Status-Service "python" }
function Restart-Python { Restart-Service "python" $PY_DIR $PY_CMD }

switch ($cmd) {
  'start' { Start-Frontend; Start-Node; Start-Python }
  'stop' { Stop-Frontend; Stop-Node; Stop-Python }
  'restart' { Restart-Frontend; Restart-Node; Restart-Python }
  'status' { Status-Frontend; Status-Node; Status-Python }
  'start:frontend' { Start-Frontend }
  'stop:frontend' { Stop-Frontend }
  'restart:frontend' { Restart-Frontend }
  'status:frontend' { Status-Frontend }
  'start:node' { Start-Node }
  'stop:node' { Stop-Node }
  'restart:node' { Restart-Node }
  'status:node' { Status-Node }
  'start:python' { Start-Python }
  'stop:python' { Stop-Python }
  'restart:python' { Restart-Python }
  'status:python' { Status-Python }
  default {
    Write-Host "Usage: service.ps1 [start|stop|restart|status|start:frontend|stop:frontend|restart:frontend|status:frontend|start:node|stop:node|restart:node|status:node|start:python|stop:python|restart:python|status:python]"
  }
}
