# tentacle

Due to required build context, all scirpts should be executed from the root directory.

## Building the container

```plaintext
docker build --tag octopusdeploy/tentacle-prerelease:3.15.8 --build-arg OctopusVersion=latest --file Tentacle\Dockerfile .
```

## Running a Tentacle: Docker compose

This will run a SQL Express container, an Octopus Server container and a Tentacle container:

```plaintext
& docker-compose --project-name octopusdocker --file Tentacle\docker-compose.yml up --force-recreate -d
```

Usage of this `docker-compose.yml` file implies acceptance of the Microsoft EULA as per https://hub.docker.com/r/microsoft/mssql-server-windows-express/.

### Environment variables

Default values are set in the `.env` file.

- **SA_PASSWORD**: SA password to use the the sql express database
- **OctopusAdminUsername**: The admin user to create for the Octopus Server
- **OctopusAdminPassword**: The password for the admin user for the Octopus Server

#### Ports

- **81**: Port for API and HTTP portal

### Volume

- **C:\Applications**: Default directory to deploy applications to.

## Running a Tentacle - Plain ol' Docker

```plaintext
docker run --publish 10931:10933 --tty --interactive --env "ListeningPort=10931" --env "ServerApiKey=API-L9WIFOCOWABUNGAQO6JMZIGWV6HI" --env "TargetEnvironment=Test" --env "TargetRole=app-server" --env "ServerUrl=https://octopus.example.com"  --env "PublicHostNameConfiguration=PublicIp" octopusdeploy/tentacle:3.15.8
```

### Environment variables

- **ServerApiKey**: The API Key of the Octopus Server the Tentacle should register with.
- **ServerUsername**: If not using an api key, the user to use when registering the Tentacle with the Octopus Servr.
- **ServerPassword**: If not using an api key, the password to use when registering the Tentacle
- **ServerUrl**: The Url of the Octopus Server the Tentacle should register with.
- **TargetEnvironment**: Comma delimited list of environments to add this target to.
- **TargetRole**: Comma delimited list of roles to add to this target.
- **TargetWorkerPool**: Comma delimited list of worker pools to add to this target to (not to be used with environments or role variable).
- **TargetName**: Optional Target name, defaults to host.
- **ServerPort**: The port on the Octopus Server that the Tentacle will poll for work. Implies a polling Tentacle.
- **ListeningPort**: The port that the Octopus Server will connect back to the Tentacle with. Defaults to 10933. Implies a listening Tentacle.
- **PublicHostNameConfiguration**: How the url that the Octopus server will use to communicate with the Tentacle is determined. Can be `PublicIp`, `FQDN`, `ComputerName` or `Custom`. Defaults to `PublicIp`.
- **CustomPublicHostName**: If `PublicHostNameConfiguration` is set to `Custom`, the host name that the Octopus Server should use to communicate with the Tentacle.

### Ports

- **10933**: Port tentacle will be listening on (if in listening mode).

## Build and deployment process

The internal Octopus build and deployment process is split into two phases.

First stage builds a docker container, and publishes it to `octopusdeploy/tentacle-prerelease`. These images are only intended for internal testing. This is primarily based around pre-release (CI) packages.

```plaintext
.\Tentacle\01-build.ps1 -TentacleVersion 3.15.8
.\Tentacle\02-start.ps1 -OctopusVersion latest -TentacleVersion 3.15.8 -username -username <user> -password <password>
.\Tentacle\03-run.ps1
.\Tentacle\04-stop.ps1 -OctopusVersion latest -TentacleVersion 3.15.8
.\Tentacle\05-publish-privately.ps1 -OctopusVersion latest -TentacleVersion 3.15.8 -username <user> -password <password>
```