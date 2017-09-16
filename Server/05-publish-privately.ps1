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

Start-TeamCityBlock "Publish to private repo"

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-prerelease:$OctopusVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion" "$tag"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Docker-Login

Push-Image "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion"

Stop-TeamCityBlock "Publish to private repo"
