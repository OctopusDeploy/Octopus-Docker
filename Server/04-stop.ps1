param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

$env:OCTOPUS_VERSION = $OctopusVersion

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

pushd Server

write-host "Stopping '$ProjectName' compose project"
& docker-compose --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& docker-compose --project-name $ProjectName down

popd
