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

function Get-DownloadUrl {
	return Get-Content c:\octopus-install.initstate
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
			DownloadUrl = Get-DownloadUrl
			
            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"			
			SqlDbConnectionString = $env:SqlDbConnectionString
            OctopusAdminCredential = Get-AdminCreds            
            AllowCollectionOfUsageStatistics = $false # dont mess with stats
            LicenseKey = $licenceKey
            OctopusMasterKey = Get-MasterKey
            
        }
        
		cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = $env:OCTOPUS_INSTANCENAME
            Enabled = $true
            DependsOn = "[cOctopusServer]$env:OCTOPUS_INSTANCENAME"
        }
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