. ./common.ps1



function Get-DownloadUrl {
	$version = $env:OctopusVersion
	$downloadUrlLatest = 'https://octopus.com/downloads/latest/WindowsX64/OctopusServer'
	$msiFileName = "Octopus.$($version)-x64.msi"
	$downloadBaseUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/" #"https://download.octopusdeploy.com/octopus/"


	if($env:DownloadUrl -ne $null){
		Write-Log "Download location provided as $env:DownloadUrl"
		return $env:DownloadUrl
	} elseif($version -eq $null) {
		Write-Log "No version specified for install. Using latest";
		return $downloadUrlLatest      
	} else {
		$downloadUrl = $downloadBaseUrl + $msiFileName
		Write-Log "Downloading msi from $downloadUrl"
		return $downloadUrl
	}
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
            State = "Installed"
            Name = $env:OCTOPUS_INSTANCENAME
            DownloadUrl = Get-DownloadUrl
            AllowCollectionOfUsageStatistics = $false
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

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
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


Write-Log "Get-DscLocalConfigurationManager returns:"
Get-DscLocalConfigurationManager


$ev = $null
Start-DscConfiguration $PSScriptRoot -Verbose -Wait -Force -ErrorVariable ev
if (($null -ne $ev) -and ($ev.Count -gt 0)) {
	throw $ev
}
Write-Log "Phase completed"