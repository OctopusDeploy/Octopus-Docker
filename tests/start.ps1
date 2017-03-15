param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$env:OCTOPUS_VERSION=$OctopusVersion;
$ServerServiceName=$ProjectName+"_octopus_1";
$TentacleServiceName=$ProjectName+"_tentacle_1";

. ./octopus-common.ps1

if(!(Test-Path .\tests\Applications)) {
	mkdir .\tests\Applications
}

write-host "docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up --force-recreate -d"
& docker-compose --project-name $ProjectName --file .\docker-compose.yml --file .\tests\docker-compose.yml up  --force-recreate  -d
if ($LASTEXITCODE -ne 0) {
  Write-Log "docker-compose failed with $LASTEXITCODE"
  & docker-compose --project-name $ProjectName logs
  exit 1
}

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


# Write out helpful info on success
$docker = (docker inspect $ServerServiceName | convertfrom-json)[0]
#$port = $docker.NetworkSettings.Ports.'81/tcp'.HostPort
$ipAddress = $docker.NetworkSettings.Networks.nat.IpAddress
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81
