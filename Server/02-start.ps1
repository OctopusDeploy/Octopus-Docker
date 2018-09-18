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
#docker run --rm --tty -e MasterKey="pxpCVJ+T6SbvJawomFWvqg==" -v C:/Temp/MasterKey:C:/MasterKey  -e sqlDbConnectionString="Server=10.0.75.1,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Password01!;MultipleActiveResultSets=False;Connection Timeout=30;" octopusdeploy/octopusdeploy-prerelease:2018.8.0-dscserver

. ./Scripts/build-common.ps1

$env:OCTOPUS_VERSION=Get-ImageVersion $OctopusVersion;
$ServerServiceName=$ProjectName+"_octopus_1";

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
