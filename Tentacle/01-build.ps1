param (
  [Parameter()]
  [string]$TentacleVersion="3.22.0",
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Build") {
  $imageVersion = Get-ImageVersion $TentacleVersion $OSVersion
  Write-Host "Creating image with tag 'octopusdeploy/tentacle-prerelease:$imageVersion'"
  if ($OSVersion -lt "1809") {
    $baseImage = "microsoft/windowsservercore"
  } else {
    $baseImage = "mcr.microsoft.com/windows/servercore"
  }

  docker build --pull --tag octopusdeploy/tentacle-prerelease:$imageVersion --build-arg SERVERCORE_VERSION=$OSVersion --build-arg BASE_IMAGE=$baseImage --build-arg TentacleVersion=$TentacleVersion --file Tentacle\Dockerfile .

  if($LastExitCode -ne 0) {
    $last = $LastExitCode
    Write-Host "Image failed to be created"
    exit $last
  } else {
    Write-Host "Image created"
  }
}
