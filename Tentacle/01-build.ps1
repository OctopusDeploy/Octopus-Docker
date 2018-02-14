param (
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Build"

if(!(Test-Path .\Logs)) {
  mkdir .\Logs | Out-Null
}
if(!(Test-Path .\Source)) {
  mkdir .\Source | Out-Null
}

Write-Host "docker pull microsoft/windowsservercore:latest"
& docker pull microsoft/windowsservercore:latest
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$imageVersion = Get-ImageVersion $TentacleVersion

#Stupid retry logic due to windows/docker error https://github.com/docker/docker/issues/27588
Write-Host "Building Octopus Tentacle"
$maxAttempts = 10
$attemptNumber = 0
while ($true) {
  $attemptNumber = $attemptNumber + 1
  write-host "Attempt #$attemptNumber to build container..."
  $result = Execute-Command "docker" "build --tag octopusdeploy/tentacle-prerelease:$imageVersion --build-arg TentacleVersion=$TentacleVersion --file Tentacle\Dockerfile ."
  $result.stdout > ".\Logs\tentacle-stdout-attempt-$attemptNumber.log"
  $result.stderr > ".\Logs\tentacle-stderr-$attemptNumber.log"
  if ($result.stderr -like "*encountered an error during Start: failure in a Windows system call: This operation returned because the timeout period expired. (0x5b4)*") {
    if ($attemptNumber -gt $maxAttempts) {
      write-host "Giving up after $attemptNumber attempts."
      Stop-TeamCityBlock "Build"
      exit 1
    }
    write-host "Docker failed - retrying..."
  } elseif ($result.ExitCode -ne 0) {
    write-host "Docker failed with an unknown error. Aborting."
    exit $result.ExitCode
  } else {
    break;
  }
}
Write-Host "Created image with tag 'octopusdeploy/tentacle-prerelease:$imageVersion'"

Stop-TeamCityBlock "Build"
