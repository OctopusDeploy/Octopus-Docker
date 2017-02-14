param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

write-output "Setting up data folder structure"
if (-not (Test-Path "c:\temp\octopus-with-docker-sql-volume")) {
  New-Item "c:\temp\octopus-with-docker-sql-volume" -Type Directory | out-null
}

write-output "Starting SQL Server container"

# rem rem Using custom image, while waiting for https://github.com/Microsoft/sql-server-samples/pull/106
# rem rem Once the official image - microsoft/mssql-server-2014-express-windows - supports health checks, we should use that
# rem docker run --interactive ^
# rem            --tty ^
# rem            --detach ^
# rem            --publish 1433:1433 ^
# rem            --name=OctopusDeploySqlServer ^
# rem            --env sa_password=Passw0rd123 ^
# rem            octopusdeploy/mssql-server-2014-express-windows
# rem 
# rem rem ########## start: wait until sql server is ready ##########
# rem set CheckCount=0
# rem :checkhealth
# rem set /a CheckCount=%CheckCount%+1
# rem if %checkcount% gtr 30 (
# rem   echo Waited 5 minutes for SQL Server to come alive, but it didn't. Aborting.
# rem   exit 1
# rem )
# rem 
# rem powershell -command ($(docker inspect OctopusDeploySqlServer) ^| ConvertFrom-Json).State.Health.Status ^| Set-Content -path '.run.tmp'
# rem set /p OctopusDeploySqlServerContainerHealth=<.run.tmp
# rem del .run.tmp
# rem 
# rem if "%OctopusDeploySqlServerContainerHealth%" equ "" (
# rem   echo SQL Server container does not exist. Aborting.
# rem   exit 2
# rem )
# rem 
# rem echo [Attempt %CheckCount%/12] OctopusDeploySqlServer container health state is '%OctopusDeploySqlServerContainerHealth%'
# rem if "%OctopusDeploySqlServerContainerHealth%" equ "starting" (
# rem     echo Sleeping for 10 seconds
# rem     powershell -command sleep 10
# rem     goto checkhealth:
# rem )
# rem if "%OctopusDeploySqlServerContainerHealth%" neq "healthy" (
# rem     docker inspect OctopusDeploySqlServer
# rem     exit 3
# rem )
# rem rem ########## end: wait until sql server is ready ##########

& docker run --publish 1433:1433 `
           --name=OctopusDeploySqlServer `
           --env sa_password=Passw0rd123 `
           --env ACCEPT_EULA=Y `
           --detach `
           microsoft/mssql-server-windows-express

write-host "Sleeping for 2 minutes until SQL Server is up and running (hacky)"
Start-Sleep -seconds 120

# hacky way of getting the container's ip address, as --link doesn't work on windows
$sqlServerContainerIpAddress = ($(docker inspect OctopusDeploySqlServer) | ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress

$sqlDbConnectionString = "Server=tcp:$sqlServerContainerIpAddress,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Passw0rd123;MultipleActiveResultSets=False;Connection Timeout=30;"
$masterkey = $env:masterkey

write-output "Starting OctopusDeploy $OctopusVersion container"
& docker run --name=OctopusDeploy `
           --publish 81:81 `
           --env sqlDbConnectionString="$sqlDbConnectionString" `
           --env masterKey="$masterkey" `
           --volume c:/temp/octopus-with-docker-sql-volume:c:/Octopus `
           --interactive `
           octopusdeploy/octopusdeploy-prerelease:$OctopusVersion

# ########## start: wait until octopus is ready ##########
$OctopusDeployCheckCount=1

# push the new version
write-host "Waiting until octopus is ready"
$timeoutMinutes = 5
$timeout = new-timespan -Minutes $timeoutMinutes
$sw = [diagnostics.stopwatch]::StartNew()
$success = $false
$sleepSeconds = 10

while ($sw.elapsed -lt $timeout) {
  $result = ($(docker inspect OctopusDeploy) | ConvertFrom-Json).State.Health.Status

  if ($result -eq "") {
    Write-output "OctopusDeploy container does not exist. Aborting."
    exit 5
  }

  write-output "[Attempt $OctopusDeployCheckCount] OctopusDeploy container health state is '$result'"

  if ($result -eq "starting") {
    write-host "Sleeping for $sleepSeconds seconds..."
    Start-Sleep -seconds $sleepSeconds
  }
  elseif ($result -ne "healthy") {
    & docker inspect OctopusDeploy
    exit 6
  }
  else {
    $success = $true
    break
  }
}
if (-not $success) {
  write-host "Giving up waiting for container to start after $timeoutMinutes minutes"
  exit 1
}

write-host "Done. Octopus is available on port 81."
