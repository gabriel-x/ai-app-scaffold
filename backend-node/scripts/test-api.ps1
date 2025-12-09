# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
$ErrorActionPreference = 'Stop'

# 定义颜色常量
$RED = "\u001b[0;31m"
$GREEN = "\u001b[0;32m"
$YELLOW = "\u001b[1;33m"
$BLUE = "\u001b[0;34m"
$NC = "\u001b[0m" # No Color

# 打印带颜色的消息
function Print-Message {
    param(
        [string]$Color,
        [string]$Message
    )
    Write-Host -ForegroundColor $Color "$Message"
}

# 脚本路径和项目根目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT = Resolve-Path "$SCRIPT_DIR/.."
$OUT_DIR = Join-Path $ROOT 'logs/api-tests'

# 确保输出目录存在
if (-not (Test-Path $OUT_DIR)) {
    New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null
}

# 获取后端端口（优先从环境变量获取，否则使用默认值）
$BACKEND_PORT = $Env:BACKEND_PORT
if (-not $BACKEND_PORT) {
    $BACKEND_PORT = 3001
}

$BASE_URL = "http://localhost:$BACKEND_PORT/api/v1"
$HEADERS = @{ 'Content-Type' = 'application/json' }

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
            Print-Message $GREEN "PASS"
            $report.summary.passed++
            $report.tests += @{ name=$name; status="PASS"; result=$res }
        } else {
            Print-Message $RED "FAIL"
            $report.summary.failed++
            $report.tests += @{ name=$name; status="FAIL"; result=$res }
        }
        return $res
    } catch {
        Print-Message $RED "ERROR: $_"
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
    Invoke-RestMethod -Method Post -Uri "$BASE_URL/auth/register" -Headers $HEADERS -Body $body
} { param($r) return $r.ok -eq $true -and $r.data.email -eq $email }

# 2. Login
Start-Sleep -Seconds 1
$loginRes = Run-Test "Login" {
    $body = @{ email=$email; password=$pwd } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$BASE_URL/auth/login" -Headers $HEADERS -Body $body
} { param($r) return $r.accessToken.Length -gt 0 -and $r.refreshToken.Length -gt 0 }

$token = $loginRes.accessToken
$refreshToken = $loginRes.refreshToken
$authHeaders = @{ Authorization="Bearer $token" }

# 3. Get Me
Run-Test "Get Me" {
    Invoke-RestMethod -Method Get -Uri "$BASE_URL/auth/me" -Headers $authHeaders
} { param($r) return $r.email -eq $email }

# 4. Refresh Token
Start-Sleep -Seconds 2
$refreshRes = Run-Test "Refresh Token" {
    $body = @{ refreshToken=$refreshToken } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$BASE_URL/auth/refresh" -Headers $HEADERS -Body $body
} { param($r) return $r.accessToken.Length -gt 0 -and $r.accessToken -ne $token }

$newToken = $refreshRes.accessToken
$newAuthHeaders = @{ Authorization="Bearer $newToken"; "Content-Type"="application/json" }

# 5. Get Profile
Run-Test "Get Profile" {
    Invoke-RestMethod -Method Get -Uri "$BASE_URL/accounts/profile" -Headers $newAuthHeaders
} { param($r) return $r.id -ne $null -and $r.name -eq $testUserName }

# 6. Update Profile
$newName = "Updated Name"
Run-Test "Update Profile" {
    $body = @{ name=$newName } | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri "$BASE_URL/accounts/profile" -Headers $newAuthHeaders -Body $body
} { param($r) return $r.name -eq $newName }

# Report
$reportJson = $report | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $OUT_DIR 'report.json') -Value $reportJson
Print-Message $BLUE "`nReport saved to $(Join-Path $OUT_DIR 'report.json')"
if ($report.summary.failed -gt 0) { exit 1 } else { exit 0 }
