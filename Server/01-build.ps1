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
  if($OSVersion -eq "ltsc2016") {
	$baseImage = "mcr.microsoft.com/dotnet/framework/runtime:4.7.2-windowsservercore-ltsc2016"
  } elseif ($OSVersion -lt "1809") {
    $baseImage = "microsoft/windowsservercore:$OSVersion"
  } else {
    $baseImage = "mcr.microsoft.com/windows/servercore:$OSVersion"
  }

  docker build --pull --tag octopusdeploy/octopusdeploy-prerelease:$imageVersion --build-arg SERVERCORE_VERSION=$OSVersion --build-arg BASE_IMAGE=$baseImage --build-arg OctopusVersion=$OctopusVersion --file Server\Dockerfile .

  if($LastExitCode -ne 0) {
    $last = $LastExitCode
    Write-Host "Image failed to be created"
    exit $last
  } else {
    Write-Host "Image created"
  }
}