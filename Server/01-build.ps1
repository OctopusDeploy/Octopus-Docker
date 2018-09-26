param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Build") {
  $imageVersion = Get-ImageVersion $OctopusVersion $OSVersion
  Write-Host "Creating image with tag 'octopusdeploy/octopusdeploy-prerelease:$imageVersion'"
  docker build --pull --tag octopusdeploy/octopusdeploy-prerelease:$imageVersion --build-arg SERVERCORE_VERSION=$OSVersion --build-arg OctopusVersion=$OctopusVersion --file Server\Dockerfile .
  
  if($LastExitCode -ne 0) {
    $last = $LastExitCode
    Write-Host "Image failed to be created"
    exit $last
  } else {
    Write-Host "Image created"
  }
  
}