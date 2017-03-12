# octopusdeploy-prerelease

## Building the container
The Dockerfile requires a `Source` directory in the build context. This directory is added so that it can first be checked for the `.msi` during the installation process. If no `.msi` exists, the build will try download the file from `https://download.octopusdeploy.com/octopus/`

```
docker build --tag octopusdeploy/octopusdeploy-prerelease:3.11.7 --build-arg OctopusVersion=3.11.7 --file Server\Dockerfile .
```



```
docker run --name OctopusDeploy --rm --volume "C:/Dev/Octopus-Docker/Server/Import:C:/Import" --publish 81:81 --env sqlDbConnectionString="Server=myServerAddress;Database=myDataBase;Trusted_Connection=True;" octopusdeploy/octopusdeploy-prerelease:3.11.7
	
```
