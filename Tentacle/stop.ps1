param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion
)

$env:OCTOPUS_VERSION=$OctopusVersion;
$env:TENTACLE_VERSION=$TentacleVersion;

write-host "Stopping '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName down
