param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$env:OCTOPUS_VERSION=$OctopusVersion;
$env:TENTACLE_VERSION=$TentacleVersion;
$ServerServiceName=$ProjectName+"_octopus_1";
$TentacleServiceName=$ProjectName+"_tentacle_1";

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Start containers"

if(!(Test-Path .\tests\Applications)) {
  mkdir .\tests\Applications | Out-Null
}

Docker-Login

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

Start-DockerCompose $ProjectName .\Tentacle\docker-compose.yml
Wait-ForServiceToPassHealthCheck $TentacleServiceName

if(!(Test-Path .\tests\Logs)) {
  mkdir .\tests\Logs | Out-Null
}

& docker logs $ServerServiceName > .\tests\Logs\OctopusServer.log
& docker logs $TentacleServiceName > .\tests\Logs\OctopusTentacle.log

$docker = (docker inspect $ServerServiceName | convertfrom-json)[0]
$ipAddress = $docker.NetworkSettings.Networks.nat.IpAddress
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81

$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""
Stop-TeamCityBlock "Start Containers"
