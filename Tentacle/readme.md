# octopusdeploy-tentacle-prerelease

## Building the container
Due to required build context, this should be executed from the root directory.
```
docker build --tag octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.7 --build-arg OctopusVersion=3.11.7 --file Tentacle\Dockerfile .
```

## Running a Tentacle: Quick Start
````
docker run --publish 10931:10933 --env "ListeningPort=10931" --env "ServerApiKey=API-L9WIFOCOWABUNGAQO6JMZIGWV6HI" --env "TargetEnvironment=Test" --env "TargetRole=bread" --env "ServerUrl=http://master.deployment.com"  --env "PublicHostNameConfiguration=PublicIp" octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.7
````

## Configuration Options

### Environment variables
 - **ServerApiKey**: The API Key of the Octopus Server the Tentacle should register with.
 - **ServerUrl**: The Url of the Octopus Server the Tentacle should register with.
 - **TargetEnvironment**: Comma delimited list of environments to add this target to.
 - **TargetRole**: Comma delimited list of roles to add to this target.
 - **TargetName**: Optional Target name, defaults to host.
 - **ListeningPort**: When using Passive Tentacles, the port that the Octopus Server will connect back to the Tentacle with. Defaults to 10933.
 - **PublicHostNameConfiguration**: PublicIp, FQDN, ComputerName or Custom. Default PublicIp 

### Ports
 - **10933**: Port tentacle will be listening on.
 
### Volume
 - **C:\Applications**: Default directory to deploy applications to.