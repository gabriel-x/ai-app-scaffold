# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param([string]$cmd = "help")
$root = (Resolve-Path "$PSScriptRoot/..").Path
$logDir = "$root/logs"
$pidFile = "$logDir/frontend.pid"
$portFile = "$root/.frontend.port"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
function Load-Env {
  if (Test-Path "$root/.env") { Get-Content "$root/.env" | ForEach-Object { if (-not $_.StartsWith('#') -and $_.Contains('=')) { $k, $v = $_.Split('='); Set-Item -Path Env:$k -Value $v } } }
  if (Test-Path "$root/.env.local") { Get-Content "$root/.env.local" | ForEach-Object { if (-not $_.StartsWith('#') -and $_.Contains('=')) { $k, $v = $_.Split('='); Set-Item -Path Env:$k -Value $v } } }
}
function Ensure-Port {
  if (Test-Path $portFile) { $port = (Get-Content $portFile | Where-Object { $_ -match '^[0-9]+$' } | Select-Object -First 1) } else { $port = $null }
  if (-not $port) { $range = $Env:FRONTEND_PORT_RANGE; if (-not $range) { $range = '10100-10190' }; $s, $e = $range.Split('-'); for ($p = [int]$s; $p -le [int]$e; $p++) { $inuse = (netstat -ano | Select-String ":$p "); if (-not $inuse) { $port = $p; break } } }
  if (-not $port) { $port = 10100 }
  Set-Content -Path $portFile -Value $port
  $Env:PORT = "$port"
}
function Get-PidByPort($p) {
  $n = netstat -ano | Select-String ":$p " | Select-Object -First 1
  if ($n) {
    $line = $n.Line.Trim()
    $parts = $line -split '\s+'
    return $parts[-1]
  }
  return $null
}

function Start-Dev {
  Load-Env
  Ensure-Port
  New-Item -ItemType File -Force -Path "$logDir/null" | Out-Null
  $p = Start-Process -FilePath npm -ArgumentList "run", "dev", "--", "--port", "$Env:PORT", "--strictPort" -WorkingDirectory $root -PassThru -RedirectStandardOutput "$logDir/frontend.log" -RedirectStandardError "$logDir/frontend.err.log" -RedirectStandardInput "$logDir/null" -WindowStyle Hidden
  
  Start-Sleep -Seconds 3
  $realPid = Get-PidByPort $Env:PORT
  if ($realPid) {
      Set-Content -Path $pidFile -Value $realPid
      Write-Host "frontend dev started on http://localhost:$Env:PORT (pid: $realPid)"
  } elseif ($p) {
      Set-Content -Path $pidFile -Value $p.Id
      Write-Host "frontend dev started on http://localhost:$Env:PORT"
  }
}

function Start-Preview {
  Load-Env
  Ensure-Port
  $build = Start-Process -FilePath npm -ArgumentList "run", "build" -WorkingDirectory $root -PassThru -RedirectStandardOutput "$logDir/build.log" -RedirectStandardError "$logDir/build.err.log" -WindowStyle Hidden
  if ($build) {
    Wait-Process -Id $build.Id -ErrorAction SilentlyContinue
    $build.Refresh()
    $exitCode = $build.ExitCode
    if ($null -eq $exitCode) { $exitCode = 0 }
    if ($exitCode -ne 0) {
      Write-Error "frontend build failed with exit code $exitCode. Check $logDir/build.err.log"
      return
    }
  }
  else { Write-Error "frontend build start failed"; return }
  New-Item -ItemType File -Force -Path "$logDir/null" | Out-Null
  $p = Start-Process -FilePath npm -ArgumentList "run", "preview", "--", "--port", "$Env:PORT", "--strictPort" -WorkingDirectory $root -PassThru -RedirectStandardOutput "$logDir/frontend.log" -RedirectStandardError "$logDir/frontend.err.log" -RedirectStandardInput "$logDir/null" -WindowStyle Hidden
  
  Start-Sleep -Seconds 3
  $realPid = Get-PidByPort $Env:PORT
  if ($realPid) {
      Set-Content -Path $pidFile -Value $realPid
      Write-Host "frontend preview started on http://localhost:$Env:PORT (pid: $realPid)"
  } elseif ($p) {
      Set-Content -Path $pidFile -Value $p.Id
      Write-Host "frontend preview started on http://localhost:$Env:PORT"
  } else {
      Write-Error "frontend preview start failed"
  }
}

function Stop-Frontend {
  if (Test-Path $pidFile) { $childPid = Get-Content $pidFile; Stop-Process -Id $childPid -Force -ErrorAction SilentlyContinue; Remove-Item $pidFile -Force }
  
  # Double check port and kill if still running
  if (Test-Path $portFile) {
      $port = Get-Content $portFile
      $portPid = Get-PidByPort $port
      if ($portPid) {
          Stop-Process -Id $portPid -Force -ErrorAction SilentlyContinue
          Write-Host "cleaned up process $portPid on port $port"
      }
  }
}

function Status-Frontend {
  $running = $false
  if (Test-Path $pidFile) {
      $childPid = Get-Content $pidFile
      if (Get-Process -Id $childPid -ErrorAction SilentlyContinue) {
          Write-Host "running(pid:$childPid)"
          $running = $true
      } else {
          Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
      }
  }
  
  if (-not $running) {
      if (Test-Path $portFile) {
          $port = Get-Content $portFile
          $portPid = Get-PidByPort $port
          if ($portPid) {
              Write-Host "running(port:$port pid:$portPid)"
              Set-Content -Path $pidFile -Value $portPid
          } else {
              Write-Host "stopped"
          }
      } else {
          Write-Host "stopped"
      }
  }
}
function Logs { Get-Content "$logDir/frontend.log" -Wait -Tail 200 }
function Health { if (Test-Path $portFile) { $p = Get-Content $portFile; try { Invoke-WebRequest -Uri "http://localhost:$p" -UseBasicParsing | Out-Null; Write-Host "200" } catch { Write-Host "error" } } else { Write-Host "no-port" } }
switch ($cmd) {
  'start' { Start-Preview }
  'start:dev' { Start-Dev }
  'stop' { Stop-Frontend }
  'restart' { Stop-Frontend; Start-Preview }
  'status' { Status-Frontend }
  'logs' { Logs }
  'health' { Health }
  default { Write-Host "usage: client-manager.ps1 [start|start:dev|stop|restart|status|logs|health]" }
}
