param(
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword,
	[ValidateNotNullOrEmpty()]
	[string]$OctopusVersion
)

$IPAddress=$(Get-IPAddress)
$OctopusURI="http://$($IPAddress):81"

 
Describe 'Octopus API' {

	$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
	$repository = new-object Octopus.Client.OctopusRepository $endpoint
		
	it 'should have the correct version installed' {
		$version = $repository.Client.RootDocument.Version
		
		$version | should be $OctopusVersion
	}
	
	it 'should should available for login' {
        $LoginObj = New-Object Octopus.Client.Model.LoginCommand 
        $LoginObj.Username = $OctopusUsername
        $LoginObj.Password = $OctopusPassword

        $repository.Users.SignIn($LoginObj)
  
        $UserObj = $repository.Users.GetCurrent()

		$UserObj.Username | should be $OctopusUsername
	}
	
	it 'should have imported the migration export' {
		$DevEnv = $repository.Environments.FindByName("Development")
		$DevEnv | should not be $null
	}
}