@echo off


if "%sqlDbConnectionString%" equ "" (
	echo Please set the sqlDbConnectionString environment variable
	exit 1
)
if "%OctopusVersion%" equ "" (
	set OctopusVersion=3.7.10
	echo No OctopusVersion environment variable set. Defaulting to %OctopusVersion%.
)

echo Setting up data folder structure
if not exist c:\temp\octopus-with-ext-sql-volume mkdir c:\temp\octopus-with-ext-sql-volume

rem hacky way of getting round docker bug https://github.com/docker/docker/issues/26178
powershell -command $env:sqlDbConnectionString -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p sqlDbConnectionString=<.run.tmp
powershell -command $env:masterKey -replace '=', '##equals##' ^| Set-Content -path '.run.tmp'
set /p masterKey=<.run.tmp

del .run.tmp

echo Starting Octopus Deploy
docker run --name OctopusDeploy ^
           --publish 81:81 ^
           --env sqlDbConnectionString="%sqlDbConnectionString%" ^
           --env masterKey=%masterkey% ^
           --volume c:/temp/octopus-with-ext-sql-volume:c:/Octopus ^
           octopusdeploy/octopusdeploy:%OctopusVersion%
