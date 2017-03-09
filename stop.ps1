param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

  
write-host "Stopping '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName down