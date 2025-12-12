# Test the Is-Service-Accessible function directly
function Is-Service-Accessible {
    param([int]$Port)
    Write-Host "Testing accessibility of http://localhost:$Port"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        Write-Host "Response: $response"
        if ($response) {
            Write-Host "StatusCode: $($response.StatusCode)"
            if ($response.StatusCode -eq 200) {
                Write-Host "Result: True"
                return $true
            }
        }
    } catch {
        Write-Host "Exception: $($_.Exception.Message)"
    }
    Write-Host "Result: False"
    return $false
}

# Test with frontend port
Write-Host "=== Testing Frontend Port 10100 ==="
$frontendAccessible = Is-Service-Accessible 10100
Write-Host "Frontend accessible: $frontendAccessible"

# Test with non-existent port
Write-Host "\n=== Testing Non-existent Port 9999 ==="
$nonAccessible = Is-Service-Accessible 9999
Write-Host "Non-existent port accessible: $nonAccessible"