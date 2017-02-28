write-host "Stopping 'OctopusDeploy' container"
& docker stop OctopusDeploy
write-host "Stopping 'OctopusDeploySqlServer' container"
& docker stop OctopusDeploySqlServer
write-host "Removing 'OctopusDeploy' container"
& docker rm OctopusDeploy
write-host "Removing 'OctopusDeploySqlServer' container"
& docker rm OctopusDeploySqlServer