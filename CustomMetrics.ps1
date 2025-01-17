# Open Firewall Port 8000
New-NetFirewallRule -DisplayName "HTTP(S) Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Force

# Create PowerShell HTTP Server Script (Equivalent to 'server.py')
$serverScript = @"
`$Hso = New-Object Net.HttpListener
`$Hso.Prefixes.Add('http://localhost:8000/')
`$Hso.Start()

Write-Host 'Starting server on port 8000...'

# Function to Generate JSON Response
function GenerateResponseJson {
    return (@{
        'ApplicationHealthState' = 'Healthy'
        'CustomMetrics' = @{
            'RollingUpgrade' = @{
                'PhaseOrderingNumber' = 1
                'SkipUpgrade' = 'false'
            }
        }
    } | ConvertTo-Json -Depth 10)
}

# Continuous Loop to Keep the Server Running
while (`$Hso.IsListening) {
    try {
        `$context = `$Hso.GetContext()
        `$response = `$context.Response
        `$response.StatusCode = 200
        `$response.ContentType = 'application/json'
        `$responseJson = GenerateResponseJson
        `$responseBytes = [System.Text.Encoding]::UTF8.GetBytes(`$responseJson)
        `$response.OutputStream.Write(`$responseBytes, 0, `$responseBytes.Length)
        `$response.Close()
        Write-Host "Responded to request at $(Get-Date)"
    }
    catch {
        Write-Host "Error occurred: $_"
    }
}
"@

# Save the script as 'server.ps1'
$scriptPath = "$env:TEMP\server.ps1"
$serverScript | Set-Content -Path $scriptPath -Encoding UTF8

# Run the PowerShell HTTP Server as a Background Process
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -PassThru | ForEach-Object {
    # Store Process ID
    $SERVER_PID = $_.Id
    Write-Host "Server has been started on port 8000 with PID $SERVER_PID"
}
