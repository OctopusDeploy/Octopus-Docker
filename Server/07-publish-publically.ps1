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

Start-TeamCityBlock "Pushing to public repo"

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-prerelease:$OctopusVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion" "$tag"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Docker-Login

Set-Tag "octopusdeploy/octopusdeploy:$OctopusVersion"
Push-Image "octopusdeploy/octopusdeploy:$OctopusVersion"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
$latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusServer/version").Version
if ($latestVersion -eq $OctopusVersion) {
  Write-Host "Tagging as latest as $latestVersion is the most recent version"
  Set-Tag "octopusdeploy/octopusdeploy:latest"
  Push-Image "octopusdeploy/octopusdeploy:latest"
} else {
  Write-Host "Not tagging as latest as $OctopusVersion is not the latest version ($latestVersion is the most recent version)"
}

Stop-TeamCityBlock "Pushing to public repo"
