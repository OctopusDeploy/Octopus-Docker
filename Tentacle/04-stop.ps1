param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion
)

$OctopusVersion="2018.8.0-dscserver"
$TentacleVersion="3.22.0"

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

$env:OCTOPUS_VERSION = $OctopusVersion
$env:TENTACLE_VERSION = Get-ImageVersion $TentacleVersion
$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"
$env:OCTOPUS_SERVER_REPO_SUFFIX = "-prerelease"

TeamCity-Block("Stop and remove compose project") {

	write-host "Stopping '$ProjectName' compose project"
	& docker-compose --file .\Tentacle\docker-compose.yml --project-name $ProjectName stop

	write-host "Removing '$ProjectName' compose project"
	& docker-compose --file .\Tentacle\docker-compose.yml --project-name $ProjectName down

  $env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""
  
  if(Test-Path .\Temp) {
    Remove-Item .\Temp -Recurse -Force
  }
}