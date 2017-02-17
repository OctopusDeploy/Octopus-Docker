param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

write-output "Setting up data folder structure"
if (-not (Test-Path "c:\temp\octopus-with-docker-sql-volume")) {
  New-Item "c:\temp\octopus-with-docker-sql-volume" -Type Directory | out-null
}

write-output "Getting latest 'octopusdeploy/mssql-server-2014-express-windows:latest' image"
& docker pull octopusdeploy/mssql-server-2014-express-windows:latest

write-output "Getting latest 'octopusdeploy/octopusdeploy-prerelease:$OctopusVersion' image"
& docker pull octopusdeploy/octopusdeploy-prerelease:$OctopusVersion

write-output "Starting SQL Server container"

# Using custom image, while waiting for https://github.com/Microsoft/sql-server-samples/pull/106
# Once the official image - microsoft/mssql-server-2014-express-windows - supports health checks, we should use that

& docker run --publish 1433:1433 `
             --name=OctopusDeploySqlServer `
             --env sa_password=Passw0rd123 `
             --env ACCEPT_EULA=Y `
             --detach `
             octopusdeploy/mssql-server-2014-express-windows:latest

########## start: wait until sql server is ready ##########
$checkCount = 0
$sleepSeconds = 10
while ($true) {
  $checkCount = $checkCount + 1
  if ($checkCount -gt 30) {
    write-host "Waited 5 minutes for SQL Server to come alive, but it didn't. Aborting."
    exit 1
  }

  $result = ($(docker inspect OctopusDeploySqlServer) | ConvertFrom-Json).State.Health.Status

  if ($result -eq "") {
    write-host "SQL Server container does not exist. Aborting."
    exit 2
  }

  write-host "[Attempt $checkCount] OctopusDeploySqlServer container health state is '$result'"
  if ($result -eq "starting") {
      write-host "Sleeping for $sleepSeconds seconds"
      powershell -command sleep $sleepSeconds
  } elseif ($result -ne "healthy") {
      & docker inspect OctopusDeploySqlServer
      exit 3
  }
}
########## end: wait until sql server is ready ##########

$sqlServerContainerIpAddress = ($(docker inspect OctopusDeploySqlServer) | ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress

$sqlDbConnectionString = "Server=tcp:$sqlServerContainerIpAddress,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Passw0rd123;MultipleActiveResultSets=False;Connection Timeout=30;"
$masterkey = $env:masterkey

write-output "Starting OctopusDeploy $OctopusVersion container"
& docker run --name=OctopusDeploy `
             --publish 81:81 `
             --env sqlDbConnectionString="$sqlDbConnectionString" `
             --env masterKey="$masterkey" `
             --volume c:/temp/octopus-with-docker-sql-volume:c:/Octopus `
             --detach `
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
