param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Pull from private repo"

$imageVersion = Get-ImageVersion $TentacleVersion

$env:OCTOPUS_VERSION=$imageVersion

Docker-Login

$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

Write-Host "docker-compose --file .\server\docker-compose.yml pull"
& docker-compose --file .\server\docker-compose.yml pull

$env:OCTOPUS_SERVER_REPO_SUFFIX=""

Stop-TeamCityBlock "Pull from private repo"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
