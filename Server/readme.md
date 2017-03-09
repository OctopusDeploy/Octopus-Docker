# octopusdeploy-prerelease

## Building the container
The Dockerfile requires a `Source` directory in the build context. This directory is added so that it can first be checked for the `.msi` during the installation process. If no `.msi` exists, the build will try download the file from `https://download.octopusdeploy.com/octopus/`

```
docker build --tag octopusdeploy/octopusdeploy-prerelease:3.11.2 --build-arg OctopusVersion=3.11.2 .
```
