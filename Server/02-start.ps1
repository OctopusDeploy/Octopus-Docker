param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$OctopusServerContainer= $ProjectName+"_octopus_1";
$env:OCTOPUS_VERSION=Get-ImageVersion $OctopusVersion $OSVersion;
$env:OCTOPUS_SERVER_REPO_SUFFIX="-prerelease"
$env:SERVERCORE_VERSION=$OSVersion
$env:OCTOPUS_SKIP_IMPORT_VERSION_CHECK="true"

if ($OSVersion -eq "ltsc2016") {
    $env:SQL_IMAGE="microsoft/mssql-server-windows-express"
} elseif ($OSVersion -eq "1709") {
    $env:SQL_IMAGE="microsoft/mssql-server-windows-express:1709"
} else { #Currently no 1803/1809 version of the official microsoft/mssql-server-windows-express repo
    $env:SQL_IMAGE="christianacca/mssql-server-windows-express:2017-latest"
}

TeamCity-Block("Start containers") {

    if(!(Test-Path .\Temp)) {
        mkdir .\Temp | Out-Null
    } else {
        Remove-Item .\Temp\* -Recurse -Force
    }
    mkdir .\Temp\MasterKey | Out-Null
    mkdir .\Temp\TaskLogs | Out-Null
    mkdir .\Temp\ConsoleLogs | Out-Null
    mkdir .\Temp\ServerLogs | Out-Null

    $sw = [Diagnostics.Stopwatch]::StartNew()
    TeamCity-Block("Running Compose") {
        Start-DockerCompose $ProjectName .\Server\docker-compose.yml
    }

    TeamCity-Block("Waiting for Health") {
        Wait-ForServiceToPassHealthCheck $OctopusServerContainer
    }
    $sw.Stop()

    docker logs $OctopusServerContainer > .\Temp\ConsoleLogs\OctopusServer.log

    Write-Host Server available after ($sw.Elapsed) from the host at http://$(Get-IPAddress):81
}

$env:OCTOPUS_SERVER_REPO_SUFFIX=""
$env:OCTOPUS_VERSION=""
$env:SERVERCORE_VERSION=""
$env:OCTOPUS_SKIP_IMPORT_VERSION_CHECK=""
