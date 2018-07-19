<#
if (-not (Test-Path c:\octopus-install.initstate)) {
    Write-Output "Octopus install initialisation file (c:\octopus-install.initstate) does not yet exist"
    exit 1
}

if (-not (Test-Path c:\octopus-configuration.initstate)) {
    Write-Output "Octopus configuration initialisation file (c:\octopus-configuration.initstate) does not yet exist"
    exit 1
}

#>

if (-not (Test-Path c:\octopus-run.initstate)) {
    Write-Output "Octopus run initialisation file (c:\octopus-run.initstate) does not yet exist"
    exit 1
}

$config = [xml](get-content 'C:\TentacleHome\tentacle.config')
$servers = (($config.'octopus-settings'.set | where-object { $_.key -eq 'Tentacle.Communication.TrustedOctopusServers' }).'#text' | ConvertFrom-Json)

if ($servers[0].CommunicationStyle -eq 1) {
  # listening Tentacle

  #No simple parameter to pass to skip SSL checking in PS until https://github.com/PowerShell/PowerShell/pull/2006
  add-type @"
      using System.Net;
      using System.Security.Cryptography.X509Certificates;
      public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
              ServicePoint srvPoint, X509Certificate certificate,
              WebRequest request, int certificateProblem) {
              return true;
          }
      }
"@
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

  try {
      $response = Invoke-WebRequest https://localhost:10933 -UseBasicParsing
      $statusCode = $response.StatusCode
      if ($statusCode -ne 200) {
          Write-Output "Octopus Tentacle is not responding correctly on http://localhost:10933 - got status code $statusCode."
          exit 1
      }
  }
  catch {
      Write-Output "Octopus Tentacle is not responding correctly on http://localhost:10933 - got exception $($_)"
      exit 1
  }

  Write-Output "Octopus Tentacle responded with a 200 OK on http://localhost:10933"
  exit 0


} else {
  # polling

  # how do we check this?
}
