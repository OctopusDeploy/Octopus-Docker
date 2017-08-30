param (
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

$IncludeTentacle = (($TentacleVersion -ne $null) -and ($TentacleVersion -ne ""))

. ./Scripts/octopus-common.ps1

if(!(Test-Path .\tests\Applications)) {
  mkdir .\tests\Applications
}

function Start-DockerCompose() {
  $PrevExitCode = -1;
  $attempts=5;

  while ($true -and $PrevExitCode -ne 0) {
    if($attempts-- -lt 0){
      & docker-compose --project-name $ProjectName logs
      write-host "Ran out of attempts to create container.";
      exit 1
    }

    if ($IncludeTentacle) {
      write-host "docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up --force-recreate -d"
      & docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up --force-recreate -d
    }
    else {
      write-host "docker-compose --project-name $ProjectName --file .\docker-compose.yml up --force-recreate -d"
      & docker-compose --project-name $ProjectName --file .\docker-compose.yml up --force-recreate -d
    }
    $PrevExitCode = $LASTEXITCODE
    if($PrevExitCode -ne 0) {
      Write-Host $Error
      Write-Host "docker-compose failed with exit code $PrevExitCode";
      if ($IncludeTentacle) {
        & docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml logs
      }
      else {
        & docker-compose --project-name $ProjectName --file .\docker-compose.yml logs
      }
    }
  }
}

function Wait-ForServerToPassHealthCheck() {
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
}

function Wait-ForTentacleToPassHealthCheck() {
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
}

Start-DockerCompose
Wait-ForServerToPassHealthCheck
if ($IncludeTentacle) {
  Wait-ForTentacleToPassHealthCheck
}

if(!(Test-Path .\tests\Logs)) {
  mkdir .\tests\Logs
}

& docker logs $ServerServiceName > .\tests\Logs\OctopusServer.log
if ($IncludeTentacle) {
  & docker logs $TentacleServiceName > .\tests\Logs\OctopusTentacle.log
}

# Write out helpful info on success
$docker = (docker inspect $ServerServiceName | convertfrom-json)[0]
if ($IncludeTentacle) {
  $docker = (docker inspect $TentacleServiceName | convertfrom-json)[0]
}

$ipAddress = $docker.NetworkSettings.Networks.nat.IpAddress
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81
