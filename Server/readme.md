# octopusdeploy-prerelease

## Building the container
Due to required build context, this should be executed from the root directory. The Dockerfile requires a `Source` directory in the build context. This directory is added so that it can first be checked for the `.msi` during the installation process. If no `.msi` exists, the build will try download the file from `https://download.octopusdeploy.com/octopus/`

## Building the container
```
docker build --tag octopusdeploy/octopusdeploy-prerelease:3.11.7 --build-arg OctopusVersion=3.11.7 --file Server\Dockerfile .
```

## Running a Server: Quick Start
```
docker run --name OctopusDeploy --publish 81:81 --env sqlDbConnectionString="Server=myServerAddress;Database=myDataBase;Trusted_Connection=True;" octopusdeploy/octopusdeploy-prerelease:3.11.7
```

## Configuration Options

### Environment variables
 - **sqlDbConnectionString**: Connection string to backing database.
 - **ServerUrl**: The Url of the Octopus Server the Tentacle should register with.
 - **TargetEnvironment**: Comma delimited list of environments to add this target to.
 - **TargetRole**: Comma delimited list of roles to add to this target.
 - **TargetName**: Optional Target name, defaults to host.
 - **ListeningPort**: When using Passive Tentacles, the port that the Octopus Server will connect back to the Tentacle with. Defaults to 10933.
 - **PublicHostNameConfiguration**: PublicIp, FQDN, ComputerName or Custom. Default PublicIp 

### Ports
 - **10943**: Port open for polling tentacles to contact on.
 - **81**: Port for API and HTTP portal.
 
### Volume
 - **C:\Import**: Imports from this folder if `metadata.json` exists then Import takes place on startup.
 - **C:\Repository**: Package path for the built-in package repository.
 - **C:\Artifacts**: Path where artifacts are stored.
 - **C:\TaskLogs**: Path where task logs are stored.