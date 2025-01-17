New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('8000')
                $Hso = New-Object Net.HttpListener
                $Hso.Prefixes.Add('http://localhost:8000/')
                $Hso.Start()
                function GenerateResponseJson()
                {
                    $appHealthState = "Healthy"
                    $hashTable = @{
                        'ApplicationHealthState' = $appHealthState
                        'CustomMetrics' = @{
                            'RollingUpgrade' = @{
                                'PhaseOrderingNumber' = 1
                                'SkipUpgrade' = "false"
                            }
                        }
                    } 
                    $hashTable.CustomMetrics = ($hashTable.CustomMetrics | ConvertTo-Json)
                    return ($hashTable | ConvertTo-Json)
                }
                While($Hso.IsListening)
                {
                    $context = $Hso.GetContext()
                    $response = $context.Response
                    $response.StatusCode = 200
                    $response.ContentType = 'application/json'
                    $responseJson = GenerateResponseJson
                    $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
                    $response.OutputStream.Write($responseBytes, 0, $responseBytes.Length)
                    $response.Close()
                }
                $Hso.Stop()
