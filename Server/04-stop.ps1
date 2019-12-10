param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

TeamCity-Block("Stop and remove compose project") {
    
    write-host "Removing $ProjectName compose project"
    & docker-compose --file .\Server\docker-compose.yml --project-name $ProjectName down -v --rmi all --remove-orphans

    if(!$(Test-RunningUnderTeamCity) -and (Test-Path .\Temp)) {
      Write-Host "Cleaning up Temp"
      Remove-Item .\Temp -Recurse -Force
    }
}