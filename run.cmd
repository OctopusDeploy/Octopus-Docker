
@cls
@if not exist logs mkdir logs
@if not exist artifacts mkdir artifacts
@if not exist packagecache mkdir packagecache
@if not exist packages mkdir packages
@if not exist tasklogs mkdir tasklogs

docker run -p 81:81 ^
           -e SqlDbConnectionString='foo=bar' ^
           -v c:/temp/Octopus/logs:c:/Octopus/Logs ^
           -v c:/temp/Octopus/artifacts:c:/Octopus/aartifacts ^
           -v c:/temp/Octopus/artifacts:c:/Octopus/OctopusServer/aartifacts ^
           -v c:/temp/Octopus/packages:c:/Octopus/ppackages ^
           -v c:/temp/Octopus/tasklogs:c:/Octopus/TaskLogs ^
           octopusdeploy/octopusdeploy:3.4.2
