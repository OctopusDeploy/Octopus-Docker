param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion,
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$imageVersion = Get-ImageVersion $TentacleVersion $OSVersion

TeamCity-Block("Publish to private repo") {

  Docker-Login

  Push-Image "octopusdeploy/tentacle-prerelease:$imageVersion"
}