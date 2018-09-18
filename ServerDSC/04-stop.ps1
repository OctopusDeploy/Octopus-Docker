param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

$env:OCTOPUS_VERSION = Get-ImageVersion $OctopusVersion
$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

TeamCity-Block("Stop and remove compose project") {
    
    write-host "Stopping '$ProjectName' compose project"
    & docker-compose --file .\ServerDSC\docker-compose.yml --project-name $ProjectName stop

    write-host "Removing '$ProjectName' compose project"
    & docker-compose --file .\ServerDSC\docker-compose.yml --project-name $ProjectName down

    $env:OCTOPUS_SERVER_REPO_SUFFIX=""

    if(Test-Path .\Temp) {
      Remove-Item .\Temp -Recurse -Force
    }
}
