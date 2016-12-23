@echo off

if "%OctopusVersion%" equ "" (
  set OctopusVersion=3.4.2
  echo No OctopusVersion environment variable set. Defaulting to %OctopusVersion%.
)

echo "docker --version"
docker --version
echo "docker version"
docker version

docker build --tag octopusdeploy/octopusdeploy-prerelease:%OctopusVersion% ^
             --build-arg OctopusVersion=%OctopusVersion% ^
             .
