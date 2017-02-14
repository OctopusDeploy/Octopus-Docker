param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

write-host "------------"
write-host "docker --version"
write-host "------------"
& docker --version
write-host "------------"
write-host "docker version"
write-host "------------"
& docker version
write-host "------------"

# todo: check to make sure there is an msi in the "source" directory

write-host "executing 'docker build --tag octopusdeploy/octopusdeploy-prerelease:$OctopusVersion --build-arg OctopusVersion=$OctopusVersion ."

& docker build --tag octopusdeploy/octopusdeploy-prerelease:$OctopusVersion --build-arg OctopusVersion=$OctopusVersion .
