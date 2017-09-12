param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion
)

$env:OCTOPUS_VERSION = $OctopusVersion
$env:TENTACLE_VERSION = $TentacleVersion

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

pushd Tentacle

write-host "Stopping '$ProjectName' compose project"
& docker-compose --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& docker-compose --project-name $ProjectName down

popd
