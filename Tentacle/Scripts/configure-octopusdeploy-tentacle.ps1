[CmdletBinding()]
Param()

$OctopusServerApiKey = $env:OctopusServerApiKey;
$OctopusServerUrl = $env:OctopusServerUrl;
$Environment = $env:Environment;
$MachineRoles = $env:MachineRoles;


. ./octopus-common.ps1


function Configure-Tentacle
{
 	
	  Write-Log "Configure Octopus Deploy Tentacle"
 
  if(!(Test-Path $TentacleExe)) {
	throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }  
  
  Write-Log "Setting directory paths ..."
  Execute-Command $TentacleExe @(
    'configure',
    '--console',
    '--instance', 'Tentacle',
	'--home', 'C:\Octopus\Tentacle',
	'--app', 'C:\Octopus\Applications\Tentacle')
  
	Write-Log "Configuring communication type ..."
  Execute-Command $TentacleExe @(
    'configure',
    '--console',
    '--instance', 'Tentacle',
	'--port', '10933',
	'--noListen', '"False"')
  
    Write-Log "Updating trust ..."
  Execute-Command $TentacleExe @(
    'configure',
    '--console',
    '--instance', 'Tentacle',
    '--reset-trust')
	
	Write-Log "Creating certificate ..."
  Execute-Command $TentacleExe @(
    'new-certificate',
    '--console',
    '--instance', 'Tentacle',
    '--if-blank'
  )
  
  Write-Log "Starting Octopus Deploy Tentacle Process"

Execute-Command $TentacleExe @(
    'service',
    '--console',
    '--instance', 'Tentacle',
	'--install'
  )
	<#
  Execute-Command $TentacleExe @(
    'configure',
    '--console',
    '--instance', 'Tentacle',
    '--trust', $OctopusServerThumbprint
  )
   
  #>
  
   
  Write-Log ""
}


# After the Tentacle is registered with Octopus, Tentacle listens on a TCP port, and Octopus connects to it. The Octopus server
# needs to know the public IP address to use to connect to this Tentacle instance. Is there a way in Windows Azure in which we can
# know the public IP/host name of the current machine?
function Get-MyPublicIPAddress
{
    Write-Verbose "Getting public IP address"

    try
    {
        $ip = Invoke-RestMethod -Uri https://api.ipify.org
    }
    catch
    {
        Write-Verbose $_
    }
    return $ip
}

function Get-PublicHostName
{
    param (
        [ValidateSet("PublicIp", "FQDN", "ComputerName", "Custom")]
        [string]$publicHostNameConfiguration = "PublicIp",
        [string]$customPublicHostName
    )
    if ($publicHostNameConfiguration -eq "Custom")
    {
        $publicHostName = $customPublicHostName
    }
    elseif ($publicHostNameConfiguration -eq "FQDN")
    {
        $computer = Get-CimInstance win32_computersystem
        $publicHostName = "$($computer.DNSHostName).$($computer.Domain)"
    }
    elseif ($publicHostNameConfiguration -eq "ComputerName")
    {
        $publicHostName = $env:COMPUTERNAME
    }
    else
    {
        $publicHostName = Get-MyPublicIPAddress
    }
    $publicHostName = $publicHostName.Trim()
    return $publicHostName
}

function Validate-Arguments() {
	if($OctopusServerApiKey -eq $null) {
		Write-Error "Missing api key. Set the 'OctopusServerApiKey' environment variable"
		exit 1;
	}

	if($OctopusServerUrl -eq $null) {
		Write-Error "Missing api key. Set the 'OctopusServerUrl' environment variable"
		exit 1;
	}	

	if($script:Environment -eq $null){
		$script:Environment = "Dev";
	}
	if($MachineRole -eq $null){
		$MachineRole = "app-server, docker-container";
	}
	
	Write-Log " - server endpoint '$OctopusServerUrl'"
	Write-Log " - api key '##########'"
	Write-Log " - environment '$Environment'"
	Write-Log " - role '$MachineRole'"
}

function Restore-Configuration() {
  if (-not(Test-Path $TentacleConfig)) {
    # work around https://github.com/docker/docker/issues/20127
    Copy-item $TentacleConfigTemp $TentacleConfig
  }
}

function Register-Tentacle(){
 Write-Log "Registering with server ..."
  
  $publicHostName=Get-PublicHostName;
 $args = @(
    'register-with',
    '--console',
    '--instance', 'Tentacle',
    '--name', 'CustomName',
	'--publicHostName', $publicHostName,
	'--apiKey', $OctopusServerApiKey,
	'--server', $OctopusServerUrl,	
	'--role','bread',
	'--force')
	
	$Environment.Split(",") | ForEach { $parms+= '--environment'; $parms += $_.Trim(); };
	#$MachineRoles.Split(",") | ForEach { $parms+= '--role'; $parms += $_.Trim(); };
	Write-Host "Env:" $Environment
	Execute-Command $TentacleExe $args;
}




function Run-Tentacle() {
Write-Log "Starting Octopus Deploy Tentacle Process"

Execute-Command $TentacleExe @(
    'service',
    '--console',
    '--instance', 'Tentacle',
	'--start'
  )
}

try
{
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy Tentacle"
  Validate-Arguments
  Write-Log "==============================================="

  Restore-Configuration
  Configure-Tentacle
  Register-Tentacle
  Run-Tentacle
  "Configuration complete." | Set-Content "c:\octopus-configuration.initstate"

  Write-Log "Configuration successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}