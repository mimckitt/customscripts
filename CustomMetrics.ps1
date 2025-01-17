# Open Firewall Port for HTTP Traffic on Port 8000
New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Force

# Create and Start HTTP Listener
$Hso = New-Object Net.HttpListener
$Hso.Prefixes.Add('http://localhost:8000/')
$Hso.Start()

Write-Host "HTTP Listener started on http://localhost:8000/. Waiting for requests..."

# Function to Generate JSON Response
function GenerateResponseJson() {
    $hashTable = @{
        'ApplicationHealthState' = "Healthy"
        'CustomMetrics' = @{
            'RollingUpgrade' = @{
                'PhaseOrderingNumber' = 1
                'SkipUpgrade' = "false"
            }
        }
    } 
    return ($hashTable | ConvertTo-Json -Depth 10)
}

# Infinite Loop to Keep the Listener Running and Respond to Requests
while ($Hso.IsListening) {
    try {
        # Wait for an HTTP request
        $context = $Hso.GetContext()
        $response = $context.Response

        # Set response headers
        $response.StatusCode = 200
        $response.ContentType = 'application/json'

        # Generate JSON response from hash table
        $responseJson = GenerateResponseJson
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseJson)

        # Send the response
        $response.OutputStream.Write($responseBytes, 0, $responseBytes.Length)
        $response.Close()

        Write-Host "Responded to request at $(Get-Date)"
    }
    catch {
        Write-Host "Error occurred: $_"
    }
}
