param (
  
  [string]$UserName,  
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

. ../Scripts/build-common.ps1

$env:OCTOPUS_VERSION=Get-ImageVersion $OctopusVersion;
$OctopusServerContainer=$ProjectName+"_octopus_1";
$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

TeamCity-Block("Start containers") {

    if(!(Test-Path ..\tests\Applications)) {
      mkdir ..\tests\Applications | Out-Null
    }
    if(!(Test-Path ..\tests\Logs)) {
      mkdir ..\tests\Logs | Out-Null
    }

    #Docker-Login

    $sw = [Diagnostics.Stopwatch]::StartNew()
    TeamCity-Block("Running Compose") {
        Start-DockerCompose $ProjectName ..\Server\docker-compose.yml
    }
    
    TeamCity-Block("Waiting for Health") {
        Wait-ForServiceToPassHealthCheck $OctopusServerContainer
    }
    $sw.Stop()

    & docker logs $OctopusServerContainer > ..\tests\Logs\OctopusServer.log

    Write-Host Server available after ($sw.Elapsed) from the host at http://$(Get-IPAddress):81

    $env:OCTOPUS_SERVER_REPO_SUFFIX=""
}