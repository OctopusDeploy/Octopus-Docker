@echo off

if "%OctopusVersion%" equ "" (
  set OctopusVersion=3.7.10
  echo No OctopusVersion environment variable set. Defaulting to %OctopusVersion%.
)

echo "docker --version"
docker --version
echo "docker version"
docker version

rem todo: check to make sure there is an msi in the "source" directory

docker build --tag octopusdeploy/octopusdeploy-prerelease:%OctopusVersion% ^
             --build-arg OctopusVersion=%OctopusVersion% ^
             .
