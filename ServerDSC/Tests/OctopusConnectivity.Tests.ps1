param(
    [ValidateNotNullOrEmpty()]
	[string]$IPAddress,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword
)


 
Describe 'Octopus API' {

	it 'should should available' {

        $OctopusURI="http://$($IPAddress):81"

         #Creating a connection
        $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
        $repository = new-object Octopus.Client.OctopusRepository $endpoint


        #Creating login object
        $LoginObj = New-Object Octopus.Client.Model.LoginCommand 
        $LoginObj.Username = $OctopusUsername
        $LoginObj.Password = $OctopusPassword

        #Loging in to Octopus
        $repository.Users.SignIn($LoginObj)
  
        #Getting current user logged in
        $UserObj = $repository.Users.GetCurrent()

		$UserObj.Username | should be $OctopusUsername
	}
}