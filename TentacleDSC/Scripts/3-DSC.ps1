#$pass = ConvertTo-SecureString $env:OctopusAdminPassword -AsPlainText -Force
#$cred = New-Object System.Management.Automation.PSCredential ($env:OctopusAdminUsername, $pass)

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

Configuration Tentacle_Install
{
    

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"
			TentacleDownloadUrl = $downloadUrl
            
			OctopusServerUrl = "http://172.23.192.1:8065"
            ApiKey = "API-ZPG0VZWHPIN3PUX6XS6LTIDYY"
            Environments = @("Development")
            Roles = @("bread")

            # How Tentacle will communicate with the server
            CommunicationMode = "Listen"
            ListenPort = $ListenPort
			RegisterWithServer = $true

            # Only required if the external port is different to the ListenPort. e.g the tentacle is behind a loadbalancer
            TentacleCommsPort = 10900

            # Where deployed applications will be installed by Octopus
            DefaultApplicationDirectory = "C:\Applications"

            # Where Octopus should store its working files, logs, packages etc
            TentacleHomeDirectory = "C:\Octopus"
        }
    }
}


Tentacle_Install -OutputPath $PSScriptRoot -Verbose -ConfigurationData $cd;


Write-Host "Get-DscLocalConfigurationManager returns:"
Get-DscLocalConfigurationManager


$ev = $null
Start-DscConfiguration $PSScriptRoot -Verbose -Wait -Force -ErrorVariable ev
if (($null -ne $ev) -and ($ev.Count -gt 0)) {
	throw $ev
}
Write-Host DONE