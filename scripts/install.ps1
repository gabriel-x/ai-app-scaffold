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

Write-Host "Install & Setup"
Require-Cmd node
Require-Cmd npm

$nodeVer = (node -v).Trim('v')
Write-Host "node: $nodeVer"
if (-not (Version-Ge $nodeVer '18.0.0')) { Write-Warning 'node >= 18 required' }

New-Item -ItemType Directory -Force -Path (Join-Path $root 'frontend/logs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root 'backend-node/logs') | Out-Null

$env:NPM_CONFIG_REGISTRY = 'https://registry.npmjs.org/'
$env:NPM_CONFIG_ALWAYS_AUTH = 'false'
$env:NPM_CONFIG_AUDIT = 'false'
$env:NPM_CONFIG_FUND = 'false'

Write-Host "Install backend-node"
Invoke-NpmInstall (Join-Path $root 'backend-node')

Write-Host "Install frontend"
Invoke-NpmInstall (Join-Path $root 'frontend')

$beEnv = Join-Path $root 'backend-node/.env'
if (-not (Test-Path $beEnv)) {
  $jwt = [Convert]::ToBase64String((New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes(32))
  @(
    'BASE_PATH=/api/v1'
    'ALLOWED_ORIGINS=*'
    "JWT_SECRET=$jwt"
  ) | Set-Content -Path $beEnv
}

$feEnv = Join-Path $root 'frontend/.env'
if (-not (Test-Path $feEnv)) { 'VITE_API_BASE_URL=http://localhost:10000' | Set-Content -Path $feEnv }

Write-Host "ready. use .\\scripts\\release.ps1 start"
