$licenceKey = if ($env:LicenceKey -eq $null) { "PExpY2Vuc2UgU2lnbmF0dXJlPSJoUE5sNFJvYWx2T2wveXNUdC9Rak4xcC9PeVVQc0l6b0FJS282bk9VM1kzMUg4OHlqaUI2cDZGeFVDWEV4dEttdWhWV3hVSTR4S3dJcU9vMTMyVE1FUT09Ij4gICA8TGljZW5zZWRUbz5PY3RvVGVzdCBDb21wYW55PC9MaWNlbnNlZFRvPiAgIDxMaWNlbnNlS2V5PjI0NDE0LTQ4ODUyLTE1NDI3LTQxMDgyPC9MaWNlbnNlS2V5PiAgIDxWZXJzaW9uPjIuMDwhLS0gTGljZW5zZSBTY2hlbWEgVmVyc2lvbiAtLT48L1ZlcnNpb24+ICAgPFZhbGlkRnJvbT4yMDE3LTEyLTA4PC9WYWxpZEZyb20+ICAgPE1haW50ZW5hbmNlRXhwaXJlcz4yMDIzLTAxLTAxPC9NYWludGVuYW5jZUV4cGlyZXM+ICAgPFByb2plY3RMaW1pdD5VbmxpbWl0ZWQ8L1Byb2plY3RMaW1pdD4gICA8TWFjaGluZUxpbWl0PjE8L01hY2hpbmVMaW1pdD4gICA8VXNlckxpbWl0PlVubGltaXRlZDwvVXNlckxpbWl0PiA8L0xpY2Vuc2U+" } else { $env:LicenceKey }


function Get-MasterKey {
    if($env:MasterKey -eq $null) {
        return $null
    }
    $mkey = ConvertTo-SecureString $env:MasterKey -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ("FAKE", $mkey)
}

function Get-AdminCreds {	
	if($env:MasterKey -eq $null) {
		if($env:OctopusAdminUsername -eq $null) {$env:OctopusAdminUsername="admin"}
		if($env:OctopusAdminPassword -eq $null) {$env:OctopusAdminPassword="Passw0rd123"}
		$pass = ConvertTo-SecureString $env:OctopusAdminPassword -AsPlainText -Force
		return New-Object System.Management.Automation.PSCredential ($env:OctopusAdminUsername, $pass)
	}
	$pass = ConvertTo-SecureString $env:OctopusAdminPassword -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ($env:OctopusAdminUsername, $pass)
}

$cd = @{
    AllNodes =
    @(
        @{
          NodeName = "localhost";
          PSDscAllowPlainTextPassword = $true;
          RebootIfNeeded = $True;
        }
    )
}


Configuration Server_Install
{
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"

            Name = $env:OCTOPUS_INSTANCENAME

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

			
			SqlDbConnectionString = $env:SqlDbConnectionString
            OctopusAdminCredential = Get-AdminCreds

            # dont mess with stats
            AllowCollectionOfUsageStatistics = $false
            
            LicenseKey = $licenceKey

            OctopusMasterKey = Get-MasterKey
        }
        
		cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = $env:OCTOPUS_INSTANCENAME
            Enabled = $true
            DependsOn = "[cOctopusServer]$env:OCTOPUS_INSTANCENAME"
        }
		
        <#
        cOctopusSeqLogger "Enable logging to seq"
        {
            InstanceType = "OctopusServer"
            Ensure = "Present"
            SeqServer = "http://localhost/seq"
            SeqApiKey = $seqApiKey
            Properties = @{ Application = "Octopus"; Server = "MyServer" }
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusEnvironment "Create 'Production' Environment"
        {
            Url = "http://localhost:81"
            Ensure = "Present"
            OctopusCredentials = $cred
            EnvironmentName = "Production"
            DependsOn = "[cOctopusServer]OctopusServer"
        }
        
        Script "Create Api Key and set environment variables for tests"
        {
            SetScript = {
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

                #connect
                $endpoint = new-object Octopus.Client.OctopusServerEndpoint "http://localhost:81"
                $repository = new-object Octopus.Client.OctopusRepository $endpoint

                #sign in
                $credentials = New-Object Octopus.Client.Model.LoginCommand
                $credentials.Username = "OctoAdmin"
                $credentials.Password = "SuperS3cretPassw0rd!"
                $repository.Users.SignIn($credentials)

                #create the api key
                $user = $repository.Users.GetCurrent()
                $createApiKeyResult = $repository.Users.CreateApiKey($user, "Octopus DSC Testing")

                #save it to enviornment variables for tests to use
                [environment]::SetEnvironmentVariable("OctopusServerUrl", "http://localhost:81", "User")
                [environment]::SetEnvironmentVariable("OctopusServerUrl", "http://localhost:81", "Machine")
                [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "User")
                [environment]::SetEnvironmentVariable("OctopusApiKey", $createApiKeyResult.ApiKey, "Machine")
            }
            TestScript = {
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
                Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

                #connect
                $endpoint = new-object Octopus.Client.OctopusServerEndpoint "http://localhost:81"
                $repository = new-object Octopus.Client.OctopusRepository $endpoint

                #sign in
                $credentials = New-Object Octopus.Client.Model.LoginCommand
                $credentials.Username = "OctoAdmin"
                $credentials.Password = "SuperS3cretPassw0rd!"
                $repository.Users.SignIn($credentials)

                #check if the api key exists
                $user = $repository.Users.GetCurrent()
                $apiKeys = $repository.Users.GetApiKeys($user)
                $apiKey = $apiKeys | where-object {$_.Purpose -eq "Octopus DSC Testing"}

                return $null -ne $apiKey
            }
            GetScript = {
                @{
                    Result = "" #probably bad
                }
            }
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerGuestAuthentication "Enable Guest Login"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerAzureADAuthentication "Enable Azure AD Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientID = "0272262a-b31d-4acf-8891-56e96d302018"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerOktaAuthentication "Enable Okta Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://dev-258251.oktapreview.com"
            ClientID = "752nx5basdskrsbqansE"
            DependsOn = "[cOctopusServer]OctopusServer"
        }

        cOctopusServerGoogleAppsAuthentication "Enable GoogleApps Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            ClientID = "5743519123-1232358520259-3634528"
            HostedDomain = "https://octopus.example.com"
            DependsOn = "[cOctopusServer]OctopusServer"
        }
        #>
    }
}

Server_Install -OutputPath $PSScriptRoot -Verbose -ConfigurationData $cd;


Write-Host "Get-DscLocalConfigurationManager returns:"
Get-DscLocalConfigurationManager


$ev = $null
Start-DscConfiguration $PSScriptRoot -Verbose -Wait -Force -ErrorVariable ev
if (($null -ne $ev) -and ($ev.Count -gt 0)) {
	throw $ev
}
Write-Host DONE