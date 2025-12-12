# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Require-Cmd($name) { if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { Write-Error "$name not found" } }
function Version-Ge($a, $b) { return ([version]$a -ge [version]$b) }

function Invoke-NpmInstall($dir) {
  Push-Location $dir
  try {
    if (Test-Path 'node_modules') { Remove-Item 'node_modules' -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path 'package-lock.json') {
      npm ci --no-audit --no-fund
    } else {
      npm install --no-audit --no-fund
    }
  }
  catch {
    npm install --registry=https://registry.npmjs.org/ --no-audit --no-fund
  }
  finally {
    Pop-Location
  }
}

function Invoke-PythonInstall($dir) {
  Push-Location $dir
  try {
    $venvPath = Join-Path $dir "venv"
    $pythonBin = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $pythonBin) {
      $pythonBin = Get-Command python -ErrorAction SilentlyContinue
      if (-not $pythonBin) {
        Write-Error "python or python3 not found"
      }
    }
    $pythonBin = $pythonBin.Source
    
    # 创建虚拟环境
    if (-not (Test-Path (Join-Path $venvPath "Scripts" "python.exe"))) {
      Write-Host "Creating virtual environment at $venvPath"
      & $pythonBin -m venv $venvPath
      
      # 升级pip
      Write-Host "Upgrading pip..."
      & "$venvPath\Scripts\python.exe" -m pip install -U pip wheel setuptools --disable-pip-version-check -q
    }
    
    # 安装依赖
    Write-Host "Installing dependencies..."
    if (Test-Path "requirements.txt") {
      & "$venvPath\Scripts\python.exe" -m pip install -r "requirements.txt" --disable-pip-version-check --no-input -q
    } elseif (Test-Path "pyproject.toml") {
      & "$venvPath\Scripts\python.exe" -m pip install fastapi uvicorn python-jose[cryptography] passlib[bcrypt] pydantic[email] pytest httpx --disable-pip-version-check --no-input -q
    }
  }
  catch {
    Write-Warning "Python installation failed: $_"
  }
  finally {
    Pop-Location
  }
}

Write-Host "Install & Setup"
Require-Cmd node
Require-Cmd npm

$nodeVer = (node -v).Trim('v')
Write-Host "node: $nodeVer"
if (-not (Version-Ge $nodeVer '18.0.0')) { Write-Warning 'node >= 18 required' }

New-Item -ItemType Directory -Force -Path (Join-Path $root 'frontend/logs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root 'backend-node/logs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root 'backend-python/logs') | Out-Null

$env:NPM_CONFIG_REGISTRY = 'https://registry.npmjs.org/'
$env:NPM_CONFIG_ALWAYS_AUTH = 'false'
$env:NPM_CONFIG_AUDIT = 'false'
$env:NPM_CONFIG_FUND = 'false'

Write-Host "Install backend-node"
Invoke-NpmInstall (Join-Path $root 'backend-node')

Write-Host "Install frontend"
Invoke-NpmInstall (Join-Path $root 'frontend')

Write-Host "Install backend-python"
Invoke-PythonInstall (Join-Path $root 'backend-python')

$beNodeEnv = Join-Path $root 'backend-node/.env'
if (-not (Test-Path $beNodeEnv)) {
  $bytes = New-Object byte[] 32
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $rng.GetBytes($bytes)
  $jwt = [Convert]::ToBase64String($bytes)
  @(
    'BASE_PATH=/api/v1'
    'ALLOWED_ORIGINS=*'
    "JWT_SECRET=$jwt"
  ) | Set-Content -Path $beNodeEnv
}

$bePythonEnv = Join-Path $root 'backend-python/.env'
if (-not (Test-Path $bePythonEnv)) {
  @(
    'BASE_PATH=/api/v1'
    'ALLOWED_ORIGINS=*'
  ) | Set-Content -Path $bePythonEnv
}

$feEnv = Join-Path $root 'frontend/.env'
if (-not (Test-Path $feEnv)) { 'VITE_API_BASE_URL=http://localhost:10000' | Set-Content -Path $feEnv }

Write-Host "ready. use .\scripts\service.ps1 start"
