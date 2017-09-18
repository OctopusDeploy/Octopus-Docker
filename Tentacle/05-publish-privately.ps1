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

Start-TeamCityBlock "Publish to private repo"
function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/tentacle-prerelease:$TentacleVersion' '$tag'"
  & docker tag "octopusdeploy/tentacle-prerelease:$TentacleVersion" "$tag"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Docker-Login

Push-Image "octopusdeploy/tentacle-prerelease:$TentacleVersion"

Stop-TeamCityBlock "Publish to private repo"
