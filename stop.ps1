write-host "Stopping 'octopusdeploy' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name octopusdeploy stop

write-host "Removing 'octopusdeploy' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name octopusdeploy down