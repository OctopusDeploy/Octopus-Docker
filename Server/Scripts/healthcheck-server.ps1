$response = Invoke-WebRequest http://localhost:81 -UseBasicParsing
$statusCode = $response.StatusCode
if ($statusCode -ne 200) {
    Write-Output "Octopus portal is not responding correctly on http://localhost:81 - got status code $statusCode."
    exit 1
}
