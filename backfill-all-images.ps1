param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password
)

$ErrorActionPreference = 'stop'

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserName, $Password)))
$octopusServerPrivateImages = @((Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} https://registry.hub.docker.com/v1/repositories/octopusdeploy/octopusdeploy-prerelease/tags).name)
$octopusServerPublicImages = @((Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} https://registry.hub.docker.com/v1/repositories/octopusdeploy/octopusdeploy/tags).name)
$tentaclePrivateImages = @((Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} https://registry.hub.docker.com/v1/repositories/octopusdeploy/tentacle-prerelease/tags).name)
$tentaclePublicImages = @((Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} https://registry.hub.docker.com/v1/repositories/octopusdeploy/tentacle/tags).name)

#todo: get this automatically
$octopusServerReleases = @('3.0.1.2063', '3.0.2.2077', '3.0.3.2084', '3.0.4.2105', '3.0.5.2124', '3.0.6.2140', '3.0.7.2204',
              '3.0.8.2251', '3.0.9.2259', '3.0.10.2278', '3.0.11.2328', '3.0.12.2366', '3.0.13.2386', '3.0.15.2418',
              '3.0.16.2438', '3.0.17.2462', '3.0.18.2471', '3.0.19.2485', '3.0.20.0', '3.0.21.0', '3.0.22.0',
              '3.0.23.0', '3.0.24.0', '3.0.25.0', '3.0.26.0', '3.1.0', '3.1.1', '3.1.2', '3.1.3', '3.1.4', '3.1.5',
              '3.1.6', '3.1.7', '3.2.0', '3.2.1', '3.2.2', '3.2.3', '3.2.4', '3.2.6', '3.2.7', '3.2.8', '3.2.9',
              '3.2.10', '3.2.11', '3.2.12', '3.2.13', '3.2.15', '3.2.16', '3.2.17', '3.2.18', '3.2.19', '3.2.20',
              '3.2.21', '3.2.22', '3.2.23', '3.2.24', '3.3.0', '3.3.1', '3.3.2', '3.3.3', '3.3.4', '3.3.5', '3.3.6',
              '3.3.7', '3.3.8', '3.3.9', '3.3.10', '3.3.11', '3.3.12', '3.3.13', '3.3.14', '3.3.15', '3.3.16',
              '3.3.17', '3.3.18', '3.3.19', '3.3.20', '3.3.21', '3.3.22', '3.3.23', '3.3.24', '3.3.25', '3.3.26',
              '3.3.27', '3.4.0', '3.4.1', '3.4.2', '3.4.3', '3.4.4', '3.4.5', '3.4.6', '3.4.7', '3.4.8', '3.4.9',
              '3.4.10', '3.4.11', '3.4.12', '3.4.13', '3.4.14', '3.4.15', '3.5.0', '3.5.1', '3.5.2', '3.5.3', '3.5.4',
              '3.5.5', '3.5.6', '3.5.7', '3.5.8', '3.5.9', '3.6.0', '3.6.1', '3.6.2', '3.7.0', '3.7.1', '3.7.2',
              '3.7.3', '3.7.4', '3.7.5', '3.7.6', '3.7.7', '3.7.8', '3.7.9', '3.7.10', '3.7.11', '3.7.12', '3.7.13',
              '3.7.14', '3.7.15', '3.7.16', '3.7.17', '3.7.18', '3.8.0', '3.8.1', '3.8.2', '3.8.3', '3.8.4', '3.8.5',
              '3.8.6', '3.8.7', '3.8.8', '3.8.9', '3.9.0', '3.10.0', '3.10.1', '3.11.0', '3.11.1', '3.11.2', '3.11.3',
              '3.11.4', '3.11.5', '3.11.6', '3.11.7', '3.11.8', '3.11.9', '3.11.10', '3.11.11', '3.11.12', '3.11.13',
              '3.11.14', '3.11.15', '3.11.16', '3.11.17', '3.11.18', '3.12.0', '3.12.1', '3.12.2', '3.12.3', '3.12.4',
              '3.12.5', '3.12.6', '3.12.7', '3.12.8', '3.12.9', '3.13.0', '3.13.1', '3.13.2', '3.13.3', '3.13.4',
              '3.13.5', '3.13.6', '3.13.7', '3.13.8', '3.13.9', '3.13.10', '3.14.1', '3.14.15', '3.14.159',
              '3.14.1592', '3.14.15926', '3.15.0', '3.15.1', '3.15.2', '3.15.3', '3.15.4', '3.15.5', '3.15.6',
              '3.15.7', '3.15.8', '3.16.0', '3.16.1', '3.16.2', '3.16.3', '3.16.4', '3.16.5', '3.16.6', '3.16.7',
              '3.17.1', '3.17.2')
$tentacleReleases = @('3.0.1.2063', '3.0.2.2077', '3.0.3.2084', '3.0.4.2105', '3.0.5.2124', '3.0.6.2140', '3.0.7.2204',
  '3.0.8.2251', '3.0.9.2259', '3.0.10.2278', '3.0.11.2328', '3.0.12.2366', '3.0.13.2386', '3.0.15.2418', '3.0.16.2438',
  '3.0.17.2462', '3.0.18.2471', '3.0.19.2485', '3.0.20.0', '3.0.21.0', '3.0.22.0', '3.0.23.0', '3.0.24.0', '3.0.25.0',
  '3.0.26.0', '3.1.0', '3.1.1', '3.1.2', '3.1.3', '3.1.4', '3.1.5', '3.1.6', '3.1.7', '3.2.0', '3.2.1', '3.2.2', '3.2.3',
  '3.2.4', '3.2.6', '3.2.7', '3.2.8', '3.2.9', '3.2.10', '3.2.11', '3.2.12', '3.2.13', '3.2.15', '3.2.16', '3.2.17',
  '3.2.18', '3.2.19', '3.2.20', '3.2.21', '3.2.22', '3.2.23', '3.2.24', '3.3.0', '3.3.1', '3.3.2', '3.3.3', '3.3.4',
  '3.3.5', '3.3.6', '3.3.7', '3.3.8', '3.3.9', '3.3.10', '3.3.11', '3.3.12', '3.3.13', '3.3.14', '3.3.15', '3.3.16',
  '3.3.17', '3.3.18', '3.3.19', '3.3.20', '3.3.21', '3.3.22', '3.3.23', '3.3.24', '3.3.25', '3.3.26', '3.3.27', '3.4.0',
  '3.4.1', '3.4.2', '3.4.3', '3.4.4', '3.4.5', '3.4.6', '3.4.7', '3.4.8', '3.4.9', '3.4.10', '3.4.11', '3.4.12', '3.4.13',
  '3.4.14', '3.4.15', '3.5.0', '3.5.1', '3.5.2', '3.5.3', '3.5.4', '3.5.5', '3.5.6', '3.5.7', '3.5.8', '3.5.9', '3.6.0',
  '3.6.1', '3.6.2', '3.7.0', '3.7.1', '3.7.2', '3.7.3', '3.7.4', '3.7.5', '3.7.6', '3.7.7', '3.7.8', '3.7.9', '3.7.10',
  '3.7.11', '3.7.12', '3.7.13', '3.7.14', '3.7.15', '3.7.16', '3.7.17', '3.7.18', '3.8.0', '3.8.1', '3.8.2', '3.8.3',
  '3.8.4', '3.8.5', '3.8.6', '3.8.7', '3.8.8', '3.8.9', '3.9.0', '3.10.0', '3.10.1', '3.11.0', '3.11.1', '3.11.2',
  '3.11.3', '3.11.4', '3.11.5', '3.11.6', '3.11.7', '3.11.8', '3.11.9', '3.11.10', '3.11.11', '3.11.12', '3.11.13',
  '3.11.14', '3.11.15', '3.11.16', '3.11.17', '3.11.18', '3.12.0', '3.12.1', '3.12.2', '3.12.3', '3.12.4', '3.12.5',
  '3.12.6', '3.12.7', '3.12.8', '3.12.9', '3.13.0', '3.13.1', '3.13.2', '3.13.3', '3.13.4', '3.13.5', '3.13.6', '3.13.7',
  '3.13.8', '3.13.9', '3.13.10', '3.14.1', '3.14.159', '3.15.0', '3.15.1', '3.15.2', '3.15.6', '3.15.7', '3.15.8')

function Test-ReleaseShouldBeRebuilt($release) {
  return @("$env:ImageRebuild") -contains $release
}

function Test-ImageExistsInBothPublicAndPrivateRepos($privateReleases, $publicReleases, $release) {
  return ($privateReleases -contains $release) -and ($publicReleases -contains $release)
}

function Test-ImageExistsInPrivateRepo($privateReleases, $release) {
  return ($privateReleases -contains $release)
}

function Publish-OctopusServerPrivateImageToPublicRepo($release) {
  write-host "Docker images for Octopus Server $release exists in the private repository. Publishing to public repo."
  write-host "##teamcity[blockOpened name='Publishing docker image for Octopus Server $release']"
  ./Server/06-pull.ps1 -OctopusVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/07-publish-publically.ps1 -OctopusVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  write-host "##teamcity[blockOpened name='Deleting local docker image for Octopus Server $release']"
  & docker rmi octopusdeploy/octopusdeploy-prerelease:$release
  & docker rmi octopusdeploy/octopusdeploy:$release
  write-host "##teamcity[blockClosed name='Deleting local docker image for Octopus Server $release']"
  write-host "##teamcity[blockClosed name='Publishing docker image for Octopus Server $release']"
}

function Start-OctopusServerImageBuildFromScratch($release) {
  write-host "##teamcity[blockOpened name='Building docker image for Octopus Server $release']"
  ./Server/01-build.ps1 -OctopusVersion $release
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/02-start.ps1 -OctopusVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/03-run.ps1
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/04-stop.ps1 -OctopusVersion $release
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/05-publish-privately.ps1 -OctopusVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Server/07-publish-publically.ps1 -OctopusVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  write-host "##teamcity[blockOpened name='Deleting local docker image for Octopus Server $release']"
  & docker rmi octopusdeploy/octopusdeploy-prerelease:$release
  & docker rmi octopusdeploy/octopusdeploy:$release
  write-host "##teamcity[blockClosed name='Deleting local docker image for Octopus Server $release']"
  write-host "##teamcity[blockClosed name='Building docker image for Octopus Server $release']"
}

function Publish-TentaclePrivateImageToPublicRepo($release) {
  write-host "Docker images Tentacle $release exists in the private repository. Publishing to public repo."
  write-host "##teamcity[blockOpened name='Publishing docker image Tentacle $release']"
  ./Tentacle/06-pull.ps1 -OctopusVersion $release -TentacleVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/07-publish-publically.ps1 -TentacleVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  write-host "##teamcity[blockOpened name='Deleting local docker image Tentacle $release']"
  & docker rmi octopusdeploy/tentacle-prerelease:$release
  & docker rmi octopusdeploy/tentacle:$release
  write-host "##teamcity[blockClosed name='Deleting local docker image Tentacle $release']"
  write-host "##teamcity[blockClosed name='Publishing docker image Tentacle $release']"
}

function Start-TentacleImageBuildFromScratch($release) {
  write-host "##teamcity[blockOpened name='Building docker image Tentacle $release']"
  ./Tentacle/01-build.ps1 -TentacleVersion $release
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/02-start.ps1 -OctopusVersion $release -TentacleVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/03-run.ps1
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/04-stop.ps1 -OctopusVersion $release -TentacleVersion $release
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/05-publish-privately.ps1 -TentacleVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  ./Tentacle/07-publish-publically.ps1 -TentacleVersion $release -UserName $UserName -Password $Password
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  write-host "##teamcity[blockOpened name='Deleting local docker image Tentacle $release']"
  & docker rmi octopusdeploy/tentacle-prerelease:$release
  & docker rmi octopusdeploy/tentacle:$release
  write-host "##teamcity[blockClosed name='Deleting local docker image Tentacle $release']"
  write-host "##teamcity[blockClosed name='Building docker image Tentacle $release']"
}

foreach($release in $octopusServerReleases) {
  if (Test-ReleaseShouldBeRebuilt $release) {
    write-host "Rebuild of docker image for Octopus Server $release requested."
    Start-OctopusServerImageBuildFromScratch $release
  }
  elseif (Test-ImageExistsInBothPublicAndPrivateRepos $octopusServerPrivateImages $octopusServerPublicImages $release) {
    write-host "Docker image for Octopus Server $release exists in both public and private repositories. Nothing to do."
  }
  elseif (Test-ImageExistsInPrivateRepo $octopusServerPrivateImages $release) {
    Publish-OctopusServerPrivateImageToPublicRepo $release
  }
  else {
    Start-OctopusServerImageBuildFromScratch $release
  }
}

foreach($release in $tentacleReleases) {
  if (Test-ReleaseShouldBeRebuilt $release) {
    write-host "Rebuild of docker image for Tentacle $release requested."
    Start-TentacleImageBuildFromScratch $release
  }
  elseif (Test-ImageExistsInBothPublicAndPrivateRepos $tentaclePrivateImages $tentaclePublicImages $release) {
    write-host "Docker image for Tentacle $release exists in both public and private repositories. Nothing to do."
  }
  elseif (Test-ImageExistsInPrivateRepo $tentaclePrivateImages $release) {
    Publish-TentaclePrivateImageToPublicRepo $release
  }
  else {
    Start-TentacleImageBuildFromScratch $release
  }
}
