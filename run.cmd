@echo off

set sqlDbConnectionString=XXX

cls
if not exist logs mkdir logs
if not exist artifacts mkdir artifacts
if not exist packagecache mkdir packagecache
if not exist packages mkdir packages
if not exist tasklogs mkdir tasklogs

rem hacky way of getting round docker bug https://github.com/docker/docker/issues/26178
powershell -command $env:sqlDbConnectionString -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p sqlDbConnectionString=<.run.tmp

del .run.tmp

docker run -p 81:81 ^
           -e sqlDbConnectionString="%sqlDbConnectionString%" ^
           -v c:/temp/Octopus/logs:c:/Octopus/Logs ^
           -v c:/temp/Octopus/artifacts:c:/Octopus/aartifacts ^
           -v c:/temp/Octopus/artifacts:c:/Octopus/OctopusServer/aartifacts ^
           -v c:/temp/Octopus/packages:c:/Octopus/ppackages ^
           -v c:/temp/Octopus/tasklogs:c:/Octopus/TaskLogs ^
           octopusdeploy/octopusdeploy:3.4.2
