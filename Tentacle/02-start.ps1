param (
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion,
  [Parameter(Mandatory=$false)]
  [string]$ProjectName = "octopusdocker"
)

$OctopusVersion="2018.6.1"
$TentacleVersion="3.22.0"
. ../Scripts/build-common.ps1




$env:OCTOPUS_VERSION=$OctopusVersion;
$env:TENTACLE_VERSION=Get-ImageVersion $TentacleVersion;
$OctopusServerContainer=$ProjectName+"_octopus_1";
$ListeningTentacleServiceName=$ProjectName+"_listeningtentacle_1";
$PollingTentacleServiceName=$ProjectName+"_pollingtentacle_1";

#Confirm-RunningFromRootDirectory

TeamCity-Block("Start containers") {
	if(!(Test-Path ..\tests\Applications)) {
      mkdir ..\tests\Applications | Out-Null
    } else {
		Remove-Item ..\tests\Applications\* -Recurse -Force
	}
	
	if(!(Test-Path ..\tests\Logs)) {
      mkdir ..\tests\Logs | Out-Null
    } else {
		Remove-Item ..\tests\Logs\* -Recurse -Force
	}
	
	#Docker-Login

	$env:OCTOPUS_TENTACLE_REPO_SUFFIX = "-prerelease"

	 TeamCity-Block("Running Compose") {
        Start-DockerCompose $ProjectName .\docker-compose.yml
    }
	
	TeamCity-Block("Waiting for Health") {
        Wait-ForServiceToPassHealthCheck $ListeningTentacleServiceName
		Wait-ForServiceToPassHealthCheck $PollingTentacleServiceName
    }
	
	& docker logs $OctopusServerContainer > ..\tests\Logs\OctopusServer.log
	& docker logs $ListeningTentacleServiceName > ..\tests\Logs\OctopusListeningTentacle.log
	& docker logs $PollingTentacleServiceName > ..\tests\Logs\OctopusPollingTentacle.log
	
	Write-Host Server available after ($sw.Elapsed) from the host at http://$(Get-IPAddress):81

	$env:OCTOPUS_TENTACLE_REPO_SUFFIX = ""
}
