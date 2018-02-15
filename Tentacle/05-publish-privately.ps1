param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$imageVersion = Get-ImageVersion $TentacleVersion

Start-TeamCityBlock "Publish to private repo"

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/tentacle-prerelease:$imageVersion' '$tag'"
  & docker tag "octopusdeploy/tentacle-prerelease:$imageVersion" "$tag"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Docker-Login

Push-Image "octopusdeploy/tentacle-prerelease:$imageVersion"

Stop-TeamCityBlock "Publish to private repo"
