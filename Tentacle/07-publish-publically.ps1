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

Set-Tag "octopusdeploy/octopusdeploy-tentacle:$TentacleVersion"
Push-Image "octopusdeploy/octopusdeploy-tentacle:$TentacleVersion"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
$latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle/version").Version
if ($latestVersion -eq $TentacleVersion) {
  Write-Host "Tagging as latest as $latestVersion is the most recent version"
  Set-Tag "octopusdeploy/octopusdeploy-tentacle:latest"
  Push-Image "octopusdeploy/octopusdeploy-tentacle:latest"
} else {
  Write-Host "Not tagging as latest as $OctopusVersion is not the latest version ($latestVersion is the most recent version)"
}
