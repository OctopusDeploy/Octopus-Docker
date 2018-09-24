@echo off

powershell -File Server\run.ps1
IF %ERRORLEVEL% NEQ 0 (
   echo Failure Reason Given is %ERRORLEVEL%
   exit /b %ERRORLEVEL%
)

echo "Start Octopus Deploy instance ..."
echo "Run started." > "c:\octopus-run.initstate"
"C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" run --instance OctopusServer --noninteractive