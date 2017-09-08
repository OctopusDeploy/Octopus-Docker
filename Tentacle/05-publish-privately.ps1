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

Push-Image "octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion"
