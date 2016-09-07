@echo off

set sqlDbConnectionString=XXX
set masterKey=YYY

cls
echo Setting up data folder structure
if not exist c:\temp\octopus-mapped-volumes\logs mkdir c:\temp\octopus-mapped-volumes\logs
if not exist c:\temp\octopus-mapped-volumes\artifacts mkdir c:\temp\octopus-mapped-volumes\artifacts
if not exist c:\temp\octopus-mapped-volumes\packagecache mkdir c:\temp\octopus-mapped-volumes\packagecache
if not exist c:\temp\octopus-mapped-volumes\packages mkdir c:\temp\octopus-mapped-volumes\packages
if not exist c:\temp\octopus-mapped-volumes\tasklogs mkdir c:\temp\octopus-mapped-volumes\tasklogs

rem hacky way of getting round docker bug https://github.com/docker/docker/issues/26178
powershell -command $env:sqlDbConnectionString -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p sqlDbConnectionString=<.run.tmp
powershell -command $env:masterKey -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p masterKey=<.run.tmp

del .run.tmp

echo Starting Octopus Deploy
docker run --publish 81:81 ^
           --env sqlDbConnectionString="%sqlDbConnectionString%" ^
           --env masterKey=%masterkey% ^
           --volume c:/temp/octopus-mapped-volumes/logs:c:/Octopus/Logs ^
           --volume c:/temp/octopus-mapped-volumes/artifacts:c:/Octopus/Artifacts ^
           --volume c:/temp/octopus-mapped-volumes/packagecache:c:/Octopus/OctopusServer/PackageCache ^
           --volume c:/temp/octopus-mapped-volumes/packages:c:/Octopus/Packages ^
           --volume c:/temp/octopus-mapped-volumes/tasklogs:c:/Octopus/TaskLogs ^
           octopusdeploy/octopusdeploy:3.4.2
