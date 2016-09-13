if (-not (Test-Path c:\octopus-install.initstate)) {
    Write-Output "Octopus install initialisation file (c:\octopus-install.initstate) does not yet exist"
    exit 1
}

if (-not (Test-Path c:\octopus-configuration.initstate)) {
    Write-Output "Octopus configuration initialisation file (c:\octopus-configuration.initstate) does not yet exist"
    exit 1
}

if (-not (Test-Path c:\octopus-run.initstate)) {
    Write-Output "Octopus run initialisation file (c:\octopus-run.initstate) does not yet exist"
    exit 1
}

$service = Get-Service "OctopusDeploy"
if ($service -eq $null) {
    Write-Output "OctopusDeploy service not found"
    exit 1
}

if ($service.Status -ne 'Running') {
    Write-Output "OctopusDeploy service is not 'running'. Current status is '$($service.Status)'."
    exit 1
}

try {
    $response = Invoke-WebRequest http://localhost:81 -UseBasicParsing
    $statusCode = $response.StatusCode
    if ($statusCode -ne 200) {
        Write-Output "Octopus portal is not responding correctly on http://localhost:81 - got status code $statusCode."
        exit 1
    }
} 
catch { 
    Write-Output "Octopus portal is not responding correctly on http://localhost:81 - got exception $($_)"
    exit 1
}

Write-Output "Octopus portal responded with a 200 OK on http://localhost:81"
exit 0
