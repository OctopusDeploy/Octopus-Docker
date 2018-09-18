param ()

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

TeamCity-Block("Stop and remove compose project") {
    
    write-host "Stopping octopusdocker compose project"
    & docker-compose --file .\Server\docker-compose.yml --project-name octopusdocker stop

    write-host "Removing octopusdocker compose project"
    & docker-compose --file .\Server\docker-compose.yml --project-name octopusdocker down

    if(Test-Path .\Temp) {
      Remove-Item .\Temp -Recurse -Force
    }
}