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

Start-TeamCityBlock "Pushing to public repo"

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/tentacle-prerelease:$TentacleVersion' '$tag'"
  & docker tag "octopusdeploy/tentacle-prerelease:$TentacleVersion" "$tag"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Docker-Login

Set-Tag "octopusdeploy/tentacle:$TentacleVersion"
Push-Image "octopusdeploy/tentacle:$TentacleVersion"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls
$latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle/version").Version
if ($latestVersion -eq $TentacleVersion) {
  Write-Host "Tagging as latest as $latestVersion is the most recent version"
  Set-Tag "octopusdeploy/tentacle:latest"
  Push-Image "octopusdeploy/tentacle:latest"
} else {
  Write-Host "Not tagging as latest as $OctopusVersion is not the latest version ($latestVersion is the most recent version)"
}

Stop-TeamCityBlock "Pushing to public repo"
