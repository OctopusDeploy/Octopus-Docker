param(
  [ValidateNotNullOrEmpty()]
	[string]$IPAddress,
  [string]$ProjectName
)

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusListeningTentacleContainer=$ProjectName+"_listeningtentacle_1";
$OctopusPollingTentacleContainer=$ProjectName+"_pollingtentacle_1";
$OctopusDBContainer=$ProjectName+"_db_1";


. ./Scripts/build-common.ps1

Describe 'Port 10933' {

	Context 'Listening Tentacle' {
		$ListeningTentacleIPAddress = $(Get-IPAddress $OctopusListeningTentacleContainer)
		$result = Test-NetConnection -Port 10933 -ComputerName $ListeningTentacleIPAddress -InformationLevel "Quiet"
		it 'should be open' {
			$result | should be $true
		}
	}

	# Context 'Polling Tentacle' {
	# 	$PollingTentacleIPAddress = $(Get-IPAddress $OctopusPollingTentacleContainer)
	# 	$result = Test-NetConnection -Port 10933 -ComputerName $PollingTentacleIPAddress -InformationLevel "Quiet"
	# 	it 'should not be open' {
	# 		$result | should be $false
	# 	}
	# }
}