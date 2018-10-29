# octopusdeploy

Due to required build context, all scirpts should be executed from the root directory.

## Building the container

```plaintext
docker "build --tag octopusdeploy/octopusdeploy-prerelease:$OctopusVersion --build-arg OctopusVersion=$OctopusVersion --file Server\Dockerfile ."
```

## Running a Server - Docker compose

This will run a SQL Express container and an Octopus Server container:

```plaintext
& docker-compose --project-name octopusdocker --file Server\docker-compose.yml up --force-recreate -d
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

- **C:\Import**: Imports from this folder if `metadata.json` exists then Import takes place on startup.
- **C:\Repository**: Package path for the built-in package repository.
- **C:\Artifacts**: Path where artifacts are stored.
- **C:\TaskLogs**: Path where task logs are stored.
- **C:\Octopus\ServerLogs**: Path where server logs are stored.

## Running a Server - Plain ol' Docker

```plaintext
docker run --name OctopusDeploy --tty --interactive --publish 81:81 --env sqlDbConnectionString="Server=myServerAddress;Database=myDataBase;Trusted_Connection=True;" octopusdeploy/octopusdeploy:2018.8.8-1803
```

### Environment variables

- **SqlDbConnectionString**: Connection string to the database to use.
- **MasterKey**: The master key to use to connect to an existing database. If not supplied, and the database does not exist, it will generate a new one. If the database does exist, this is mandatory.
- **OctopusAdminUsername**: The admin user to create for the Octopus Server.
- **OctopusAdminPassword**: The password for the admin user for the Octopus Server.
- **ImportPassword**: Password used used during the import process (if the `C:\Import` volume  mount has been provided).

### Ports

- **81**: Port for API and HTTP portal
- **10943**: Port for Polling Tentacles to contact the server

## Build and deployment process

The internal Octopus build and deployment process is split into two phases.

First stage builds a docker container, and publishes it to `octopusdeploy/octopusdeploy-prerelease`. These images are only intended for internal testing. This is primarily based around pre-release (CI) packages.

```plaintext
.\Server\01-build.ps1 -OctopusVersion 2018.8.8 -OSVersion 1803
.\Server\02-start.ps1 -OctopusVersion 2018.8.8 -OSVersion 1803
.\Server\03-test.ps1 -OctopusVersion 2018.8.8 -OSVersion 1803
.\Server\04-stop.ps1
.\Server\05-publish-privately.ps1 -OctopusVersion 2018.8.8 -OSVersion 1803 -UserName <user> -Password <password>
```
