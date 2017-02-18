@echo off
cls

echo Checking to make sure Sql Server container is up and running
powershell -command ($(docker inspect OctopusDeploySqlServer) ^| ConvertFrom-Json).State.Health.Status ^| Set-Content -path ".test.tmp"
set /p OctopusDeploySqlServerContainerHealth=<".test.tmp"
if exist ".test.tmp" del ".test.tmp"

if "%OctopusDeploySqlServerContainerHealth%" neq "healthy" (
  echo  - OctopusDeploySqlServer container is not healthy - health status is '%OctopusDeploySqlServerContainerHealth%'. Aborting.
  exit 1
)
echo  - OctopusDeploySqlServer container is healthy

echo Checking to make sure OctopusDeploy container is up and running
powershell -command ($(docker inspect OctopusDeploy) ^| ConvertFrom-Json).State.Health.Status ^| Set-Content -path '.test.tmp'
set /p OctopusDeployContainerHealth=<.test.tmp
if exist ".test.tmp" del ".test.tmp"

if "%OctopusDeployContainerHealth%" neq "healthy" (
  echo  - OctopusDeploy container is not healthy - health status is '%OctopusDeployContainerHealth%'. Aborting.
  exit 2
)
echo  - OctopusDeploy container is healthy

powershell -command ($(docker inspect OctopusDeploy) ^| ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress ^| Set-Content -path '.test.tmp'
set /p OctopusContainerIpAddress=<.test.tmp
if exist ".test.tmp" del ".test.tmp"

if "%OctopusContainerIpAddress%" equ "" (
    echo OctopusDeploy Container does not exist. Aborting.
    exit 3
)

echo Testing basic probe of http://%OctopusContainerIpAddress%:81/app returns 200 OK

docker run --env OctopusContainerIpAddress=%OctopusContainerIpAddress% ^
           --name OctopusDeploySmokeTest ^
           --rm ^
           microsoft/windowsservercore ^
           powershell -command "try { $result = (Invoke-WebRequest http://%OctopusContainerIpAddress%:81/app -UseBasicParsing); if ($result.StatusCode -eq 200) { write-host 'Success!'; exit 0 }; Write-Host 'Failed!'; exit 1 } catch { Write-Host 'Exception! ' + $_; exit 2 }"

docker cp Scripts/run-tests.ps1 OctopusDeploy:/run-tests.ps1
docker cp Scripts/octopus-server_spec.rb OctopusDeploy:/octopus-server_spec.rb
docker exec OctopusDeploy "powershell -file /run-tests.ps1"
