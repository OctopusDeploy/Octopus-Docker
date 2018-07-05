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

$downloadUrl = Get-DownloadUrl

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
            DownloadUrl = $downloadUrl
            AllowCollectionOfUsageStatistics = $false
        }
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

$downloadUrl | Out-File c:\octopus-install.initstate -NoNewline
Write-Log "Phase completed"