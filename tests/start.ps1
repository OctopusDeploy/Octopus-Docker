param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$env:OCTOPUS_VERSION=$OctopusVersion;
$ServerServiceName=$ProjectName+"_octopus_1";
$TentacleServiceName=$ProjectName+"_tentacle_1";

. ./Scripts/octopus-common.ps1

if(!(Test-Path .\tests\Applications)) {
  mkdir .\tests\Applications
}

function Try-UpCompose() {
  $PrevExitCode = -1;
  $attempts=5;
  write-host "docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up --force-recreate -d"

  while ($true -and $PrevExitCode -ne 0) {
    if($attempts-- -lt 0){
      & docker-compose --project-name $ProjectName logs
      write-host "Ran out of attempts to create container.";
      exit 1
    }

    & docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up  --force-recreate  -d
    $PrevExitCode = $LASTEXITCODE
    if($PrevExitCode -ne 0) {
      Write-Host $Error
      Write-Host "docker-compose failed with exit code $PrevExitCode";
      & docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml logs
    }
  }
}

Try-UpCompose


# Wait for health check to indicate its alive!
$attempts = 0;
$sleepsecs = 5;
While($attempts -lt 20)
{
  $attempts++
  $health = ($(docker inspect $ServerServiceName) | ConvertFrom-Json).State.Health.Status;
  Write-Host "Waiting for Server to be healthy (current: $health)..."
  if ($health -eq "healthy"){
    break;
  }
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  Sleep -Seconds $sleepsecs
}
if ((($(docker inspect $ServerServiceName) | ConvertFrom-Json).State.Health.Status) -ne "healthy"){
  Write-Error "Octopus container failed to go healthy after $($attempts * $sleepsecs) seconds";
  exit 1;
}


# Wait for health check to indicate its alive!
$attempts = 0;
$sleepsecs = 5;
While($attempts -lt 20)
{
  $attempts++
  $health = ($(docker inspect $TentacleServiceName) | ConvertFrom-Json).State.Health.Status;
  Write-Host "Waiting for Tentacle to be healthy (current: $health)..."
  if ($health -eq "healthy"){
    break;
  }
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  Sleep -Seconds $sleepsecs
}
if ((($(docker inspect $TentacleServiceName) | ConvertFrom-Json).State.Health.Status) -ne "healthy"){
  Write-Error "Octopus Tentacle container failed to go healthy after $($attempts * $sleepsecs) seconds";
  exit 1;
}

if(!(Test-Path .\tests\Logs)) {
  mkdir .\tests\Logs
}

& docker logs  $ServerServiceName > .\tests\Logs\OctopusServer.log
& docker logs  $TentacleServiceName > .\tests\Logs\OctopusTentacle.log


# Write out helpful info on success
$docker = (docker inspect $ServerServiceName | convertfrom-json)[0]
#$port = $docker.NetworkSettings.Ports.'81/tcp'.HostPort
$ipAddress = $docker.NetworkSettings.Networks.nat.IpAddress
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81
