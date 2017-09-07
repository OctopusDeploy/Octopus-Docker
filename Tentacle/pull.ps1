param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion
)

. ../Scripts/build-comon.ps1

$env:OCTOPUS_VERSION=$OctopusVersion
$env:TENTACLE_VERSION=$TentacleVersion;

Write-Host "docker-compose --file .\docker-compose.yml pull"
& docker-compose --file .\docker-compose.yml pull
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
