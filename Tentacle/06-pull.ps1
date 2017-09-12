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

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

$env:OCTOPUS_VERSION=$OctopusVersion
$env:TENTACLE_VERSION=$TentacleVersion

Docker-Login

Write-Host "docker-compose --file .\Tentacle\docker-compose.yml pull"
& docker-compose --file .\Tentacle\docker-compose.yml pull

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
