@echo off
cls

powershell -command ($(docker inspect OctopusDeploy) ^| ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress ^| Set-Content -path '.run.tmp'
set /p OctopusContainerIpAddress=<.run.tmp
del .run.tmp

if "%OctopusContainerIpAddress%" equ "" (
    echo OctopusDeploy Container has no ip address.
    exit 1
)

:checkhealth
powershell -command ($(docker inspect OctopusDeploy) ^| ConvertFrom-Json).State.Health.Status ^| Set-Content -path '.run.tmp'
set /p OctopusContainerHealth=<.run.tmp
del .run.tmp
echo OctopusDeploy container health state is '%OctopusContainerHealth%'

if "%OctopusContainerHealth%" equ "starting" (
    echo Sleeping for 5 seconds
    powershell -command sleep 5
    goto checkhealth:
)
echo Testing basic probe of http://%OctopusContainerIpAddress%:81/app returns 200 OK

docker run --env OctopusContainerIpAddress=%OctopusContainerIpAddress% ^
           --name OctopusDeploySmokeTest ^
           --rm ^
           microsoft/windowsservercore ^
           powershell -command "try { $result = (Invoke-WebRequest http://%OctopusContainerIpAddress%:81/app -UseBasicParsing); if ($result.StatusCode -eq 200) { write-host 'Success!'; exit 0 }; Write-Host 'Failed!'; exit 1 } catch { Write-Host 'Exception! ' + $_; exit 2 }"