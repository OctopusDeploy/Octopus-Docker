param (
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion="2018.8.9",
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion="3.22.0",
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)

. ./Scripts/build-common.ps1


$env:OCTOPUS_VERSION=$OctopusVersion;
$env:TENTACLE_VERSION=Get-ImageVersion $TentacleVersion $OSVersion; 
$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"
$OctopusServerContainer=$ProjectName+"_octopus_1";
$ListeningTentacleServiceName=$ProjectName+"_listeningtentacle_1";
$PollingTentacleServiceName=$ProjectName+"_pollingtentacle_1";

Confirm-RunningFromRootDirectory


if($OSVersion -ge 1803) { #Currently no 1803/1809 version of the official microsoft/mssql-server-windows-express repo
    $env:SQL_IMAGE="christianacca/mssql-server-windows-express:$OSVersion"
} elseif($OSVersion -eq "ltsc2016") {
    $env:SQL_IMAGE="microsoft/mssql-server-windows-express"
}

TeamCity-Block("Start containers") {
	if(Test-Path .\Temp) {
		Remove-Item .\Temp -Recurse -Force
	} else {
		mkdir .\Temp	| Out-Null
	}

	mkdir .\Temp\Applications | Out-Null
	mkdir .\Temp\Logs | Out-Null

	mkdir .\Temp\PollingApplications | Out-Null
	mkdir .\Temp\PollingHome | Out-Null

	mkdir .\Temp\ListeningApplications | Out-Null
	mkdir .\Temp\ListeningHome | Out-Null
	
	#Docker-Login



	 TeamCity-Block("Running Compose") {
        Start-DockerCompose $ProjectName .\Tentacle\docker-compose.yml
    }
	
	TeamCity-Block("Waiting for Health") {
        Wait-ForServiceToPassHealthCheck $ListeningTentacleServiceName
		Wait-ForServiceToPassHealthCheck $PollingTentacleServiceName
    }
	
	& docker logs $OctopusServerContainer > .\Temp\Logs\OctopusServer.log
	& docker logs $ListeningTentacleServiceName > .\Temp\Logs\OctopusListeningTentacle.log
	& docker logs $PollingTentacleServiceName > .\Temp\Logs\OctopusPollingTentacle.log
	
	Write-Host Server available after ($sw.Elapsed) from the host at http://$(Get-IPAddress):81

	$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""
}
