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

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-prerelease:$OctopusVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion" "$tag"
}

Docker-Login

Set-Tag "octopusdeploy/octopusdeploy-preview:$OctopusVersion"
Push-Image "octopusdeploy/octopusdeploy-preview:$OctopusVersion"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
$latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusServer/version").Version
if ($latestVersion -eq $OctopusVersion) {
  Write-Host "Tagging as latest as $latestVersion is the most recent version"
  Set-Tag "octopusdeploy/octopusdeploy-preview:latest"
  Push-Image "octopusdeploy/octopusdeploy-preview:latest"
} else {
  Write-Host "Not tagging as latest as $OctopusVersion is not the latest version ($latestVersion is the most recent version)"
}
