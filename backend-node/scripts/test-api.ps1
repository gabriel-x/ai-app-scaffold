# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/..").Path
$outDir = Join-Path $root 'logs/api-tests'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$base = 'http://localhost:10000/api/v1'
$headers = @{ 'Content-Type' = 'application/json' }
$report = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    tests = @()
    summary = @{ total=0; passed=0; failed=0 }
}

function Run-Test {
    param($name, $action, $check)
    $report.summary.total++
    Write-Host -NoNewline "Testing $name... "
    try {
        $res = & $action
        $passed = & $check $res
        if ($passed) {
            Write-Host "PASS" -ForegroundColor Green
            $report.summary.passed++
            $report.tests += @{ name=$name; status="PASS"; result=$res }
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            $report.summary.failed++
            $report.tests += @{ name=$name; status="FAIL"; result=$res }
        }
        return $res
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $report.summary.failed++
        $report.tests += @{ name=$name; status="ERROR"; error="$_" }
        return $null
    }
}

# 1. Register
$email = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
$pwd = "Passw0rd!123"
$testUserName = "Test User"
$regRes = Run-Test "Register" {
    $body = @{ email=$email; password=$pwd; name=$testUserName } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$base/auth/register" -Headers $headers -Body $body
} { param($r) return $r.ok -eq $true -and $r.data.email -eq $email }

# 2. Login
Start-Sleep -Seconds 1
$loginRes = Run-Test "Login" {
    $body = @{ email=$email; password=$pwd } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Headers $headers -Body $body
} { param($r) return $r.accessToken.Length -gt 0 -and $r.refreshToken.Length -gt 0 }

$token = $loginRes.accessToken
$refreshToken = $loginRes.refreshToken
$authHeaders = @{ Authorization="Bearer $token" }

# 3. Get Me
Run-Test "Get Me" {
    Invoke-RestMethod -Method Get -Uri "$base/auth/me" -Headers $authHeaders
} { param($r) return $r.email -eq $email }

# 4. Refresh Token
Start-Sleep -Seconds 2
$refreshRes = Run-Test "Refresh Token" {
    $body = @{ refreshToken=$refreshToken } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$base/auth/refresh" -Headers $headers -Body $body
} { param($r) return $r.accessToken.Length -gt 0 -and $r.accessToken -ne $token }

$newToken = $refreshRes.accessToken
$newAuthHeaders = @{ Authorization="Bearer $newToken"; "Content-Type"="application/json" }

# 5. Get Profile
Run-Test "Get Profile" {
    Invoke-RestMethod -Method Get -Uri "$base/accounts/profile" -Headers $newAuthHeaders
} { param($r) return $r.id -ne $null -and $r.name -eq $testUserName }

# 6. Update Profile
$newName = "Updated Name"
Run-Test "Update Profile" {
    $body = @{ name=$newName } | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri "$base/accounts/profile" -Headers $newAuthHeaders -Body $body
} { param($r) return $r.name -eq $newName }

# Report
$reportJson = $report | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $outDir 'report.json') -Value $reportJson
Write-Host "`nReport saved to $outDir/report.json"
if ($report.summary.failed -gt 0) { exit 1 } else { exit 0 }
