@echo off

if "%OctopusVersion%" equ "" (
  set OctopusVersion=3.4.2
  echo No OctopusVersion environment variable set. Defaulting to %OctopusVersion%.
)

docker build --tag octopusdeploy/octopusdeploy:%OctopusVersion% ^
             --build-arg OctopusVersion=%OctopusVersion% ^
             .
