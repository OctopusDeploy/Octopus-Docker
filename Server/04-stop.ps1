param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

$env:OCTOPUS_VERSION = $OctopusVersion

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Stop and remove compose project"

$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

write-host "Stopping '$ProjectName' compose project"
& docker-compose --file .\Server\docker-compose.yml --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& docker-compose --file .\Server\docker-compose.yml --project-name $ProjectName down

$env:OCTOPUS_SERVER_REPO_SUFFIX=""

Stop-TeamCityBlock "Stop and remove compose project"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
