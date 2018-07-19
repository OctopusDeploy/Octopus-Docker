param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion
)
$OctopusVersion="2018.6.1"
$TentacleVersion="3.22.0"

. ../Scripts/build-common.ps1

$env:OCTOPUS_VERSION = $OctopusVersion
$env:TENTACLE_VERSION = Get-ImageVersion $TentacleVersion

#Confirm-RunningFromRootDirectory
    TeamCity-Block("Stop and remove compose project") {

	$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

	write-host "Stopping '$ProjectName' compose project"
	& docker-compose --file .\docker-compose.yml --project-name $ProjectName stop

	write-host "Removing '$ProjectName' compose project"
	& docker-compose --file .\docker-compose.yml --project-name $ProjectName down

	$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""
}