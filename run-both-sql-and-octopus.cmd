@echo off

set masterKey=XXX

cls
echo Setting up data folder structure
if not exist c:\temp\octopus-mapped-volumes\logs mkdir c:\temp\octopus-mapped-volumes\logs
if not exist c:\temp\octopus-mapped-volumes\artifacts mkdir c:\temp\octopus-mapped-volumes\artifacts
if not exist c:\temp\octopus-mapped-volumes\packagecache mkdir c:\temp\octopus-mapped-volumes\packagecache
if not exist c:\temp\octopus-mapped-volumes\packages mkdir c:\temp\octopus-mapped-volumes\packages
if not exist c:\temp\octopus-mapped-volumes\tasklogs mkdir c:\temp\octopus-mapped-volumes\tasklogs

rem hacky way of getting round docker bug https://github.com/docker/docker/issues/26178
powershell -command $env:masterKey -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p masterKey=<.run.tmp

echo Starting SQL Server
docker run --interactive ^
           --tty ^
           --detach ^
           --publish 1433:1433 ^
           --name=OctopusDeploySqlServer ^
           --env sa_password=Password1! ^
           microsoft/mssql-server-2014-express-windows

echo Waiting 10 seconds for sql server to start and change SA password
powershell -command sleep 10

rem hacky way of getting the container's ip address, as --link doesn't work on windows
powershell -command ($(docker inspect OctopusDeploySqlServer) ^| ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress ^| Set-Content -path '.run.tmp'
set /p sqlServerContainerIpAddress=<.run.tmp

set sqlDbConnectionString=Server=tcp:%sqlServerContainerIpAddress%,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Password1!;MultipleActiveResultSets=False;Connection Timeout=30;
rem hacky way of getting round docker bug https://github.com/docker/docker/issues/26178
powershell -command $env:sqlDbConnectionString -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p sqlDbConnectionString=<.run.tmp

del .run.tmp

echo Starting OctopusDeploy
docker run --name=OctopusDeploy ^
           --publish 81:81 ^
           --env sqlDbConnectionString="%sqlDbConnectionString%" ^
           --env masterKey=%masterkey% ^
           --volume c:/temp/octopus-mapped-volumes/logs:c:/Octopus/Logs ^
           --volume c:/temp/octopus-mapped-volumes/artifacts:c:/Octopus/Artifacts ^
           --volume c:/temp/octopus-mapped-volumes/packagecache:c:/Octopus/OctopusServer/PackageCache ^
           --volume c:/temp/octopus-mapped-volumes/packages:c:/Octopus/Packages ^
           --volume c:/temp/octopus-mapped-volumes/tasklogs:c:/Octopus/TaskLogs ^
           octopusdeploy/octopusdeploy:3.4.2
           