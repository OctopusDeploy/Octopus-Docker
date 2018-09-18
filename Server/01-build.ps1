param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Build") {
  $imageVersion = Get-ImageVersion $OctopusVersion
  
  docker build --pull --tag octopusdeploy/octopusdeploy-prerelease:$imageVersion --build-arg OctopusVersion=$OctopusVersion --file Server\Dockerfile .
  Write-Host "Created image with tag 'octopusdeploy/octopusdeploy-prerelease:$imageVersion'"

}