@echo off

if "%OctopusVersion%" equ "" (
  set OctopusVersion=3.7.10
  echo No OctopusVersion environment variable set. Defaulting to %OctopusVersion%.
)

echo "docker --version"
docker --version
echo "docker version"
docker version

IF DEFINED BASE_URL GOTO VAR_EXISTS
SET BASE_URL=https://download.octopusdeploy.com/octopus/

:VAR_EXISTS

IF NOT EXIST Source mkdir Source
powershell -command "write-host Downloading %BASE_URL%Octopus.$($env:OctopusVersion)-x64.msi to Source/Octopus.$($env:OctopusVersion)-x64.msi"
powershell -command "invoke-webrequest %BASE_URL%/Octopus.$($env:OctopusVersion)-x64.msi -outfile Source/Octopus.$($env:OctopusVersion)-x64.msi"

powershell -command "gci -recurse"

docker build --tag octopusdeploy/octopusdeploy-prerelease:%OctopusVersion% ^
             --build-arg OctopusVersion=%OctopusVersion% ^
             .
