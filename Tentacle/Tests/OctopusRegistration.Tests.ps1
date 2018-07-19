param(
    [ValidateNotNullOrEmpty()]
	[string]$IPAddress,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword
)
$OctopusURI="http://$($IPAddress):81"

function Registration-Tests($Tentacles){
	it 'should have been registered' {
		$Tentacles.Count | should be 1
	}

	it 'should be healthy' {		
		$Tentacles[0].HealthStatus | should be "Healthy"
	}

	it 'should have the correct version installed' {
		$Tentacles[0].Endpoint.TentacleVersionDetails.Version | should be "3.22.0"
	}
}

Describe 'Octopus Registration' {
	$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
	$repository = new-object Octopus.Client.OctopusRepository $endpoint
	$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
	$LoginObj.Username = $OctopusUsername
	$LoginObj.Password = $OctopusPassword

	$repository.Users.SignIn($LoginObj)

	$task = $repository.Tasks.ExecuteCalamariUpdate();
	$repository.Tasks.WaitForCompletion($task, 4, 3);

	$task = $repository.Tasks.ExecuteHealthCheck();
	$repository.Tasks.WaitForCompletion($task, 4, 3);

	$Machines = $repository.Machines.FindAll()

	Context 'Polling Tentacle' {
		$PollingTentacles = $($Machines | where {$_.Endpoint.CommunicationStyle -eq [Octopus.Client.Model.CommunicationStyle]::TentacleActive})
		Registration-Tests $PollingTentacles
	}

	Context 'Listening Tentacle' {
		$ListeningTentacles = $($Machines | where {$_.Endpoint.CommunicationStyle -eq [Octopus.Client.Model.CommunicationStyle]::TentaclePassive})
		Registration-Tests $ListeningTentacles
		
	}
	
	# it 'should have imported the migration export' {
	# 	$DevEnv = $repository.Environments.FindByName("Development")
	# 	$DevEnv | should not be $null
	# }

}
