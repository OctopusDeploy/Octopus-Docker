These images can be used to bring up an instance of an Octopus Server or Tentacle in a container.

**Docker on windows is still relatively new, and should be used with caution.**

# Pre-Requisites

Docker containers are supported on Windows Server 2016 and Windows 10. 

Make sure you've enabled the containers feature:

```
Enable-WindowsOptionalFeature -Online -FeatureName containers –All
```

If you want to run with [Hyper-V isolation](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container), enable Hyper-V as well:

```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V –All
```

You will also need [Docker for Windows](https://www.docker.com/community-edition#/windows) installed.

# Usage

This repo is setup mainly around building and publishing the official Octopus Deploy docker images. As such, while it is still useful as a starting point to run Octopus and/or Tentacles in a container for other scenarios, this is not the goal of this repo. You should take and modify the `docker-compose.yml` files for your scenario.

## Octopus Server

The following command will launch a SQL Server Express container along with an Octopus Server. On startup, it will create a new database. Note that this database will be destroyed on termination.

```
docker-compose --file .\Server\docker-compose.yml up
```

By default the `latest` tagged image will be used. To use a specific version, set the `OCTOPUS_VERSION` environment variable.
During launch, Octopus will create a new database and once ready, Octopus will be available on port 81. You can open the Octopus portal by running:

```
$docker = docker inspect server_octopus_1 | convertfrom-json
start "http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81"
```

Note that the database will be created inside the container - it will be deleted when the containers are removed. If you wish to retain your database, either modify the `docker-compose.yml` file to use an external database server, or [map a volume and use external db files](https://hub.docker.com/r/microsoft/mssql-server-windows-express/).

Usage of this `docker-compose.yml` file implies acceptance of the Microsoft EULA as per https://hub.docker.com/r/microsoft/mssql-server-windows-express/.

Please see the [Server ReadMe](./Tentacle/readme.md) for more information.

## Tentacle

To launch a Database/Octopus Server/Tentacle setup, use the folowing command:

```
docker-compose --file .\Tentacle\docker-compose.yml up
```

As above, this will create a database on launch, and destroy it when the containers are removed. 

Run the following to open the Octopus portal:

```
$docker = docker inspect tentacle_octopus_1 | convertfrom-json
start "http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81"
```

Usage of this `docker-compose.yml` file implies acceptance of the Microsoft EULA as per https://hub.docker.com/r/microsoft/mssql-server-windows-express/.

Please see the [Tentacle ReadMe](./Tentacle/readme.md) for more information.

## A note on MasterKeys and passwords ##

Octopus makes use of MasterKeys for [security and encryption](http://docs.octopusdeploy.com/display/OD/Security+and+encryption). When the container is first run, it will generate a new MasterKey and store it on the data volume supplied. It uses this key to talk to the database, so if you want to keep the data in the database, please do not lose this key.

You can configure that to work against a previous database by adding a line to the `.env` file by adding a line: masterkey

## Support status ##

Docker on Windows is still in its infancy.

Here be dragons.

Please let us know how you get along, and how we can make it better. Pull requests definitely appreciated.

## Additional Information ##

* The default admin credentials are `admin` / `Passw0rd123`. This can (and should) be overridden in the `.env` file ... or by setting environment variables, or by passing `-e OctopusAdminUsername=XXX -e OctopusAdminPassword=YYY` ...

* These images are based off the [Octopus-Docker](https://github.com/OctopusDeploy/Octopus-Docker) repo on GitHub.
