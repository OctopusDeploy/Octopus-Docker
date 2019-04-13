param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

TeamCity-Block("Stop and remove compose project") {
    
    write-host "Stopping $ProjectName compose project"
    & docker-compose --file .\Server\docker-compose.yml --project-name $ProjectName stop

    write-host "Removing $ProjectName compose project"
    & docker-compose --file .\Server\docker-compose.yml --project-name $ProjectName down

    write-host "Stopping any other containers with`"$ProjectName`" prefix"
    docker ps -a --format "{{.Names}}" | where {$_.StartsWith($ProjectName)} | forEach { docker rm -f $_ }
    
    if(!$(Test-RunningUnderTeamCity) -and (Test-Path .\Temp)) {
      Write-Host "Cleaning up Temp"
      Remove-Item .\Temp -Recurse -Force
    }
}