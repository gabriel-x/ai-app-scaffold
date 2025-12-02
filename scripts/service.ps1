# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param([string]$cmd = "help")

function Start-Frontend { Set-Location ../frontend; npm run dev }
function Start-Node { Set-Location ../backend-node; npm run dev }
function Start-Python { Set-Location ../backend-python; uvicorn app.main:app --port $env:PORT }

switch ($cmd) {
  'start' { Start-Job { Start-Frontend }; Start-Job { Start-Node } }
  'start:frontend' { Start-Frontend }
  'start:node' { Start-Node }
  'start:python' { Start-Python }
  default { Write-Host "Usage: service.ps1 [start|start:frontend|start:node|start:python]" }
}

