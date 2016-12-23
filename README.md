This image can be used to bring up an instance of Octopus in a container.

**This is a preview, and is not supported**

**This is for demonstration and test purposes only and should not be used to run a production server.**

# Usage #

On a Windows Server 2016 TP5 server, with the containers feature installed, run:

```
	docker run --name OctopusDeploy ^
	           --publish 81:81 ^
	           --env sqlDbConnectionString="..." ^
	           --volume c:/work/octopus-data:c:/Octopus ^
	           octopusdeploy/octopusdeploy
```

Once launched, Octopus will be available on http://your-docker-host.example.com:81. Due to networking limitations in Windows Server 2016 TP5, Octopus is not available from the host server, only from containers on that server or other servers.

A [batch file is available](https://github.com/OctopusDeploy/Octopus-Docker/blob/master/start-with-external-sql.cmd) that makes it a bit easier to use and does the escaping.

## Setting up a server to run containers on ##

The easiest way to setup a server on which to run docker containers is to follow [these instructions](https://msdn.microsoft.com/en-au/virtualization/windowscontainers/quick_start/quick_start_windows_server).

## A note on MasterKeys ##

Octopus makes use of MasterKeys for [security and encryption](http://docs.octopusdeploy.com/display/OD/Security+and+encryption). When the container is first run, it will generate a new MasterKey and store it on the data volume supplied. It uses this key to talk to the database, so if you want to keep the data in the database, please do not lose this key.

If you want to use an existing database, you can pass it into `docker run` as an environment variable `--env MasterKey=XXX`. Again, if it has equals in it, then these need to be escaped. 

## Support status ##

Docker on Windows is still in its infancy.
Windows 2016 has not yet hit RTM.
These images are just a preview and are unsupported.

Here be dragons.

All that said, please let us know how you get along, and how we can make it better.

## Additional Information ##

* The default admin credentials are `admin` / `Passw0rd123`. This can (and should) be overridden by passing `--OctopusAdminUsername=XXX --OctopusAdminPassword=YYY`.

* These images are based off the [Octopus-Docker](https://github.com/OctopusDeploy/Octopus-Docker) repo on GitHub.
