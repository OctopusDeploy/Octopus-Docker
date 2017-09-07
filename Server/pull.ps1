param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ../Scripts/build-comon.ps1

$env:OCTOPUS_VERSION=$OctopusVersion

Write-Host "docker-compose --file .\docker-compose.yml pull"
& docker-compose --file .\docker-compose.yml pull
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
