# octopusdeploy-tentacle-prerelease



#"http://master.octopushq.com"
#"API-BZ1RNCOBH312W0PKCP6OQ3UZL4"


## Building the container
During the build phase of the container the (Octopus Deploy DSC)[https://github.com/OctopusDeploy/OctopusDSC/blob/master/README-cTentacleAgent.md] is used to install the tentacle. 
```
docker build --tag octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.2 --build-arg OctopusVersion=3.11.2 .
```

## Running a Tentacle: Quick Start
````
docker run --publish 10931:10933 --env "ListeningPort=10931" --env "ServerApiKey=API-L9WIFOPVJEMKVIQO6JMZIGWV6HI" --env "TargetEnvironment=Test" --env "TargetRole=bread" --env "ServerUrl=http://master.octopushq.com" octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.2
````

docker run --env "ServerApiKey=API-KXYINUKCEU5WMLKLKPP6GKPHCLU" --env "TargetEnvironment=Test" --env "TargetRole=bread" --env "ServerUrl=http://172.20.136.4:81" octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.2





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