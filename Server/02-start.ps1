param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$env:OCTOPUS_VERSION=$OctopusVersion;
$ServerServiceName=$ProjectName+"_octopus_1";

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Start containers"

if(!(Test-Path .\tests\Applications)) {
  mkdir .\tests\Applications | Out-Null
}

Docker-Login

$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

Start-DockerCompose $ProjectName .\Server\docker-compose.yml
Wait-ForServiceToPassHealthCheck $ServerServiceName

if(!(Test-Path .\tests\Logs)) {
  mkdir .\tests\Logs | Out-Null
}

& docker logs $ServerServiceName > .\tests\Logs\OctopusServer.log

$docker = (docker inspect $ServerServiceName | convertfrom-json)[0]
$ipAddress = $docker.NetworkSettings.Networks.nat.IpAddress
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81

$env:OCTOPUS_SERVER_REPO_SUFFIX=""
Stop-TeamCityBlock "Start Containers"
