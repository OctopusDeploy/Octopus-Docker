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

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion" "$tag"
}

Docker-Login

Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:$TentacleVersion"
Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:$TentacleVersion"

$latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle/version")
if ($latestVersion -eq $TentacleVersion) {
  Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:latest"
  Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:latest"
}

