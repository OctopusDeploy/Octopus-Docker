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

Start-TeamCityBlock "Stop and remove compose project"

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

write-host "Stopping '$ProjectName' compose project"
& docker-compose --file .\Tentacle\docker-compose.yml --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& docker-compose --file .\Tentacle\docker-compose.yml --project-name $ProjectName down

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""

Stop-TeamCityBlock "Stop and remove compose project"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
