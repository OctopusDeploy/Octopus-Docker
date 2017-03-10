[CmdletBinding()]
Param()

$ServerApiKey = $env:ServerApiKey;
$ServerUrl = $env:ServerUrl;
$MachineEnvironment = $env:MachineEnvironment;
$MachineRole = $env:MachineRole;

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
	'--home', 'C:\TentacleHome',
	'--app', 'C:\Applications')
  
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

function Validate-Variables() {
	if($ServerApiKey -eq $null) {
		Write-Error "Missing 'ServerApiKey' environment variable"
		exit 1;
	}

	if($ServerUrl -eq $null) {
		Write-Error "Missing 'ServerUrl' environment variable"
		exit 1;
	}	

	if($MachineEnvironment -eq $null) {
		Write-Error "Missing 'MachineEnvironment' environment variable"
		exit 1;
	}
	
	if($MachineRole -eq $null) {
		Write-Error "Missing 'MachineRole' environment variable"
		exit 1;
	}
	
	Write-Log " - server endpoint '$ServerUrl'"
	Write-Log " - api key '##########'"
	Write-Log " - environment '$MachineEnvironment'"
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
  New-Variable -Name argz -Option AllScope
$argz = @(
    'register-with',
    '--console',
    '--instance', 'Tentacle',
    '--name', 'CustomName',
	'--publicHostName', $publicHostName,
	'--apiKey', $ServerApiKey,
	'--server', $ServerUrl,
	'--force')
		
	$MachineEnvironment.Split(",") | ForEach { 
		$argz += '--environment'; 
		$argz += $_.Trim();
	 };
	 
	 $MachineRole.Split(",") | ForEach { 
		$argz += '--role'; 
		$argz += $_.Trim();
	 };

	Write-Host "Env:" $MachineEnvironment
	Write-Host "ArgsL" $argz
	
	Execute-Command $TentacleExe $argz;
}

function Run-Tentacle() {
Write-Log "Starting Octopus Deploy Tentacle Process"

Execute-Command $TentacleExe @(
    'run',
	'--console',
    '--instance', 'Tentacle'
  )
}

try
{
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy Tentacle"
  Validate-Variables
  Write-Log "==============================================="

  Restore-Configuration
  Configure-Tentacle
  Register-Tentacle
  "Configuration complete." | Set-Content "c:\octopus-configuration.initstate"

  Write-Log "Configuration successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}