# Simple test script to check frontend status exit code
Write-Host "Running frontend status command..."
& d:\Dev\win-scaffold\frontend\scripts\client-manager.ps1 status
$exitCode = $LASTEXITCODE
Write-Host "Frontend status exit code: $exitCode"

Write-Host "\nRunning service.ps1 status..."
& d:\Dev\win-scaffold\scripts\service.ps1 status
$exitCode = $LASTEXITCODE
Write-Host "service.ps1 status exit code: $exitCode"