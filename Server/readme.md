# octopusdeploy

Due to required build context, all scirpts should be executed from the root directory. The Dockerfile requires a `Source` directory in the build context, so that it can first be checked for the `.msi` during the installation process. This directory is created if necessary by the helper scripts. If no `.msi` exists, the build will try download the file from `https://download.octopusdeploy.com/octopus/`.

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

## Running a Server - Plain ol' Docker

```plaintext
docker run --name OctopusDeploy --tty --interactive --publish 81:81 --env sqlDbConnectionString="Server=myServerAddress;Database=myDataBase;Trusted_Connection=True;" octopusdeploy/octopusdeploy:3.17.0
```

### Environment variables

- **SqlDbConnectionString**: Connection string to the database to use.
- **MasterKey**: The master key to use to connect to an existing database. If not supplied, and the database does not exist, it will generate a new one. If the database does exist, this is mandatory.
- **OctopusAdminUsername**: The admin user to create for the Octopus Server.
- **OctopusAdminPassword**: The password for the admin user for the Octopus Server.

### Ports

- **81**: Port for API and HTTP portal
- **10943**: Port for Polling Tentacles to contact the server

## Build and deployment process

The internal Octopus build and deployment process is split into two phases.

First stage builds a docker container, and publishes it to `octopusdeploy/octopusdeploy-prerelease`. These images are only intended for internal testing. This is primarily based around pre-release (CI) packages.

```plaintext
.\Server\01-build.ps1 3.17.0
.\server\02-start.ps1 -OctopusVersion 3.17.0 -username -username <user> -password <password>
.\server\03-run.ps1
.\server\04-stop.ps1 -OctopusVersion 3.17.0
.\server\05-publish-privately.ps1 -OctopusVersion 3.17.0 -username <user> -password <password>
```

Once all tests have completed, it gets published to the world. This _usually_ only happens for released builds.

```plaintext
.\server\06-pull.ps1 -OctopusVersion 3.17.0 -username -username <user> -password <password>
.\server\07-publish-publically.ps1 -OctopusVersion 3.17.0 -username -username <user> -password <password>
```
