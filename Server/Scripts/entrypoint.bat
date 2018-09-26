@echo off

powershell -File Server\configure.ps1
IF %ERRORLEVEL% NEQ 0 (
   echo Failure Reason Given is %ERRORLEVEL%
   exit /b %ERRORLEVEL%
)

Server\run.bat