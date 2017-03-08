param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

$env:OCTOPUS_VERSION=$OctopusVersion

write-host "docker login -u=`"$UserName`" -p=`"#########`""
& docker login -u="$UserName" -p="$Password"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "docker-compose pull"
& "C:\Program Files\Docker Toolbox\docker-compose" pull
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "docker-compose --project-name octopusdocker up --force-recreate -d"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name octopusdocker up --force-recreate -d
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

# Wait for health check to indicate its alive!
$attempts = 0;
$sleepsecs = 5;
While($attempts -lt 20)
{	
	$attempts++
	$health = ($(docker inspect octopusdocker_octopus_1) | ConvertFrom-Json).State.Health.Status;
	Write-Host "Waiting status of healthy ($health)..."
	if ($health -eq "healthy"){
		break;
	}
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
	Sleep -Seconds $sleepsecs
}
if ((($(docker inspect octopusdocker_octopus_1) | ConvertFrom-Json).State.Health.Status) -ne "healthy"){
	Write-Error "Octopus container failed to go healthy after $($attempts * $sleepsecs) seconds";
	exit 1;
}

# Write out helpful info on success
$docker = docker inspect octopusdocker_octopus_1 | convertfrom-json
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81
