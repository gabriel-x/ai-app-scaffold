# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param([string]$cmd = "help")
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Backend($c) { & (Join-Path $root 'backend-node/scripts/server-manager.ps1') $c }
function Frontend($c) { & (Join-Path $root 'frontend/scripts/client-manager.ps1') $c }

function Start-All { Backend 'start'; Frontend 'start'; Write-Host 'started. use health/status' }
function Stop-All { Backend 'stop'; Frontend 'stop'; Write-Host 'all stopped' }
function Status-All { Write-Host 'backend:'; Backend 'status'; Write-Host 'frontend:'; Frontend 'status' }
function Logs-All { Write-Host 'backend:'; & (Join-Path $root 'backend-node/scripts/server-manager.ps1') 'logs'; Write-Host 'frontend:'; & (Join-Path $root 'frontend/scripts/client-manager.ps1') 'logs' }
function Health-All { Write-Host 'backend:'; Backend 'health'; Write-Host 'frontend:'; Frontend 'health' }
function Start-Dev { Backend 'start:dev'; Frontend 'start:dev' }

switch ($cmd) {
  'start' { Start-All }
  'stop' { Stop-All }
  'status' { Status-All }
  'logs' { Logs-All }
  'health' { Health-All }
  'start:dev' { Start-Dev }
  default { Write-Host 'usage: release.ps1 [start|stop|status|logs|health|start:dev]' }
}
