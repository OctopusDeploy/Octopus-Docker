param(
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword,
	[ValidateNotNullOrEmpty()]
	[string]$OctopusVersion,
	[ValidateNotNullOrEmpty()]
    [string]$OSVersion,
    [ValidateNotNullOrEmpty()]
	[string]$ProjectName
)

$DBPassword="N0tS3cr3t!"
$ImageVersion = $(Get-ImageVersion $OctopusVersion $OSVersion);
#$MasterKey=$(Get-Content .\Temp\MasterKey\OctopusServer)

function LoginTest ($containerName, $username, $password) {
	$IPAddress=$(Get-IPAddress $containerName)
	$OctopusURI="http://$($IPAddress):81"
	$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
	$repository = new-object Octopus.Client.OctopusRepository $endpoint
	$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
	$LoginObj.Username = $username
	$LoginObj.Password = $password
	$repository.Users.SignIn($LoginObj)
	$UserObj = $repository.Users.GetCurrent()

	$UserObj.Username | should be $username
}

$defaultContainerName=$ProjectName+"_octopusdefaultcreds_1"
$customContainerName=$ProjectName+"_octopuscustomcreds_1"
$customUsername="stevie"
$customPassword="P@55word" 

Describe 'Startup Parameters' {

	BeforeAll {
		Write-Host "Creating container With Custom Credentials"
		docker run --name $customContainerName -d --interactive --rm `
			--env OctopusAdminPassword=$customPassword `
			--env OctopusAdminUsername=$customUsername `
			--env sqlDbConnectionString="Server=db,1433;Initial Catalog=Octopus-CustomCreds;Persist Security Info=False;User ID=sa;Password=$DBPassword;MultipleActiveResultSets=False;Connection Timeout=30;" `
			octopusdeploy/octopusdeploy-prerelease:$ImageVersion

		Write-Host "Creating container With Default Credentials"
		docker run --name $defaultContainerName -d --interactive --rm `
			--env sqlDbConnectionString="Server=db,1433;Initial Catalog=Octopus-DefaultCreds;Persist Security Info=False;User ID=sa;Password=$DBPassword;MultipleActiveResultSets=False;Connection Timeout=30;" `
			octopusdeploy/octopusdeploy-prerelease:$ImageVersion
	}	

	AfterAll {
		docker stop $customContainerName | Out-Null
		docker stop $defaultContainerName | Out-Null
	}


	it 'should use custom credentials if supplied' {
		Write-Host "Waiting for container With Custom Credentials"
		Wait-ForServiceToPassHealthCheck $customContainerName

		Write-Host "Testing Login In With Custom Credentials"
		LoginTest  $customContainerName $customUsername $customPassword
	}

	it 'should use default credentials if none supplied' {
		Write-Host "Waiting for container With Default Credentials"
		Wait-ForServiceToPassHealthCheck $defaultContainerName

		Write-Host "Testing Login In With Default Credentials"
		LoginTest  $OctopusServerContainer "admin" "Passw0rd123"
	}
}