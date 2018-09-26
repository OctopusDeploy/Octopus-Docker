param (
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$OctopusVersion="2018.8.0-dscserver"
$TentacleVersion="3.22.0"
. ./Scripts/build-common.ps1


$env:OCTOPUS_VERSION=$OctopusVersion;
$env:TENTACLE_VERSION=Get-ImageVersion $TentacleVersion;
$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"
$env:OCTOPUS_SERVER_REPO_SUFFIX = "-prerelease"
$OctopusServerContainer=$ProjectName+"_octopus_1";
$ListeningTentacleServiceName=$ProjectName+"_listeningtentacle_1";
$PollingTentacleServiceName=$ProjectName+"_pollingtentacle_1";

Confirm-RunningFromRootDirectory

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
