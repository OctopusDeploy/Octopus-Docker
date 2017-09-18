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

Start-TeamCityBlock "Pull from private repo"

$env:OCTOPUS_VERSION=$OctopusVersion
$env:TENTACLE_VERSION=$TentacleVersion

Docker-Login

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

Write-Host "docker-compose --file .\Tentacle\docker-compose.yml pull"
& docker-compose --file .\Tentacle\docker-compose.yml pull

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""

Stop-TeamCityBlock "Pull from private repo"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
