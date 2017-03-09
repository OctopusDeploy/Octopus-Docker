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
docker run --publish 1433:1433 --env "OctopusServerApiKey=API-ZKCQ5ICDCK9FQV3SJHEPZGRGESS" --env "OctopusServerUrl=http://master.octopushq.com" --volume "c:/temp:c:/Octopus" octopusdeploy/octopusdeploy-tentacle-prerelease:3.11.2
````

## Ports
 - **1433**: Port tentacle will be listening on.


## Environment variables
 - **OctopusServerApiKey**: The API Key of the Octopus Server the Tentacle should register with.
 - **OctopusServerUrl**: The Url of the Octopus Server the Tentacle should register with..