. ./common.ps1

$version = $env:OctopusVersion

$downloadUrlLatest = 'https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle'
$msiFileName = "Octopus.Tentacle.$($version)-x64.msi"
$downloadBaseUrl = "https://download.octopusdeploy.com/octopus/"


if($env:DownloadUrl -ne $null){
    $downloadUrl = $env:DownloadUrl
    Write-Log "Download location provided as $env:DownloadUrl"
} elseif($version -eq $null) {
    Write-Log "No version specified for install. Using latest";
    $downloadUrl = $downloadUrlLatest      
} else {
    $downloadUrl = $downloadBaseUrl + $msiFileName
    Write-Log "Downloading msi from $downloadUrl"
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

#$password = Get-Content .\ExamplePassword.txt | ConvertTo-SecureString
$password = ConvertTo-SecureString "Password01!" -AsPlainText -Force
$ServiceCred = New-Object PSCredential "ServiceUser", $password



Configuration Tentacle_Install
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort)

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Stopped"

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"
			TentacleDownloadUrl = $downloadUrl
            
			#OctopusServerUrl = $OctopusServerUrl
            #ApiKey = $ApiKey
            #Environments = $Environments
            #Roles = $Roles

            # How Tentacle will communicate with the server
            CommunicationMode = "Listen"
            ListenPort = $ListenPort
			RegisterWithServer = $false
            
			#TentacleServiceCredential = $ServiceCred

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