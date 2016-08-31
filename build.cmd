cls
SET OctopusVersion=3.4.2
docker build --tag octopusdeploy/octopusdeploy:%OctopusVersion% ^
             --build-arg OctopusVersion=%OctopusVersion% ^
             .
