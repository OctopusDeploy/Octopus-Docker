param (
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion="2018.8.6-robsremovegcserv0176",
  [Parameter(Mandatory=$false)]
  [string]$OSVersion="1709"
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Build") {
  $imageVersion = Get-ImageVersion $OctopusVersion $OSVersion
  Write-Host "Creating image with tag 'octopusdeploy/octopusdeploy-combined:$imageVersion'"
  docker build --tag octopusdeploy/octopusdeploy-combined:$imageVersion --build-arg OctopusVersion=$OctopusVersion --file Combined\Dockerfile .
  
  if($LastExitCode -ne 0) {
    $last = $LastExitCode
    Write-Host "Image failed to be created"
    exit $last
  } else {
    Write-Host "Image created"
  }
  
}