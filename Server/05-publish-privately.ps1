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

$imageVersion = Get-ImageVersion $OctopusVersion

TeamCity-Block("Publish to private repo") {

  Docker-Login

  Push-Image "octopusdeploy/octopusdeploy-prerelease:$imageVersion"
}