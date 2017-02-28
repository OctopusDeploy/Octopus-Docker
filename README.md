This image can be used to bring up an instance of Octopus in a container.

**This is a preview, and is not supported**

**This is for demonstration and test purposes only and should not be used to run a production server.**

# Usage #

On Windows 10 with [Docker for Windows](https://www.docker.com/products/docker#/windows) installed, just run:

```
docker-compose up
```

Once launched, Octopus will be available on port 81, and you can find the NATed address by running:

```
$docker = docker inspect octopusdocker_octopus_1 | convertfrom-json
start "http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81"
```

## Setting up a server to run containers on ##

The easiest way to setup a server on which to run docker containers is to follow [these instructions](https://msdn.microsoft.com/en-au/virtualization/windowscontainers/quick_start/quick_start_windows_server).

## A note on MasterKeys and passwords ##

Octopus makes use of MasterKeys for [security and encryption](http://docs.octopusdeploy.com/display/OD/Security+and+encryption). When the container is first run, it will generate a new MasterKey and store it on the data volume supplied. It uses this key to talk to the database, so if you want to keep the data in the database, please do not lose this key.

You can configure that to work against a previous database by adding a line to the `.env` file by adding a line: masterkey

## Support status ##

This project is still in it's infancy.

Here be dragons.

That said, please let us know how you get along, and how we can make it better.

## Additional Information ##

* The default admin credentials are `admin` / `Passw0rd123`. This can (and should) be overridden in the `.env` file ... or by setting environment variables, or by passing `-e OctopusAdminUsername=XXX -e OctopusAdminPassword=YYY` ...

* These images are based off the [Octopus-Docker](https://github.com/OctopusDeploy/Octopus-Docker) repo on GitHub.
