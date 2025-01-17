# Define the script path
$scriptPath = "$env:TEMP\server.ps1"

# Create the PowerShell HTTP Server Script
$serverScript = @"
`$Hso = New-Object Net.HttpListener
`$Hso.Prefixes.Add('http://localhost:8000/')
`$Hso.Start()

Write-Host 'Starting server on port 8000...'

# Function to Generate JSON Response
function GenerateResponseJson {
    `$customMetrics = @{
        'RollingUpgrade' = @{
            'PhaseOrderingNumber' = 1
            'SkipUpgrade' = 'false'
        }
    }

    `$response = @{
        'ApplicationHealthState' = 'Healthy'
        'CustomMetrics' = `$customMetrics
    }

    return (`$response | ConvertTo-Json -Depth 10)
}

# Keep the server running
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

# Write script to file
$serverScript | Out-File -FilePath $scriptPath -Encoding UTF8

# Verify if the file exists before starting the process
if (Test-Path $scriptPath) {
    Write-Host "Server script successfully created at $scriptPath"
    Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -PassThru | ForEach-Object {
        # Store Process ID
        $SERVER_PID = $_.Id
        Write-Host "Server has been started on port 8000 with PID $SERVER_PID"
    }
} else {
    Write-Host "Error: Server script not found at $scriptPath"
}
