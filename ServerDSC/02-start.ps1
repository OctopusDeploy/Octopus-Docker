param (
  
  [string]$UserName,  
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$env:OCTOPUS_VERSION=Get-ImageVersion $OctopusVersion;
$OctopusServerContainer=$ProjectName+"_octopus_1";
$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"

TeamCity-Block("Start containers") {

    if(!(Test-Path .\Temp)) {
        mkdir .\Temp | Out-Null
    } else {
        Remove-Item .\Temp\* -Recurse -Force
    }
    mkdir .\Temp\MasterKey | Out-Null
    mkdir .\Temp\TaskLogs | Out-Null
    mkdir .\Temp\ConsoleLogs | Out-Null
  
    #Docker-Login

    $sw = [Diagnostics.Stopwatch]::StartNew()
    TeamCity-Block("Running Compose") {
        Start-DockerCompose $ProjectName .\ServerDSC\docker-compose.yml
    }
    
    TeamCity-Block("Waiting for Health") {
        Wait-ForServiceToPassHealthCheck $OctopusServerContainer
    }
    $sw.Stop()

    & docker logs $OctopusServerContainer > .\Temp\ConsoleLogs\OctopusServer.log

    Write-Host Server available after ($sw.Elapsed) from the host at http://$(Get-IPAddress):81

    $env:OCTOPUS_SERVER_REPO_SUFFIX=""
}