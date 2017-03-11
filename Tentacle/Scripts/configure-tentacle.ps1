[CmdletBinding()]
Param()

$ServerApiKey = $env:ServerApiKey;
$ServerUsername = $env:ServerUsername;
$ServerPassword = $env:ServerPassword;
$ServerUrl = $env:ServerUrl;
$TargetEnvironment = $env:TargetEnvironment;
$TargetRole = $env:TargetRole;
$TargetName=$env:TargetName;
$ListeningPort=$env:ListeningPort;
$PublicHostNameConfiguration=$env:PublicHostNameConfiguration

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
	'--port', 10933,
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
# know the public IP/host name of the current 10?
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

	if($TargetEnvironment -eq $null) {
		Write-Error "Missing 'TargetEnvironment' environment variable"
		exit 1;
	}
	
	if($TargetRole -eq $null) {
		Write-Error "Missing 'TargetRole' environment variable"
		exit 1;
	}
	
	if($PublicHostNameConfiguration -eq $null) {
		$script:PublicHostNameConfiguration = 'ComputerName'
	}
	
	if($ListeningPort -eq $null){
		$script:ListeningPort = 10933
	}
		
	Write-Log " - server endpoint '$ServerUrl'"
	Write-Log " - api key '##########'"
	Write-Log " - registered port $ListeningPort"
	Write-Log " - environment '$TargetEnvironment'"
	Write-Log " - role '$TargetRole'"
	Write-Log " - host '$PublicHostNameConfiguration'"
	if($env:TargetName -ne $null) {
		Write-Log " - name '$env:TargetName'"
	}
}

function Restore-Configuration() {
  if (-not(Test-Path $TentacleConfig)) {
    # work around https://github.com/docker/docker/issues/20127
    Copy-item $TentacleConfigTemp $TentacleConfig
  }
}

function Register-Tentacle(){
 Write-Log "Registering with server ..."
  
  $publicHostName=Get-PublicHostName $PublicHostNameConfiguration;
  New-Variable -Name argz -Option AllScope
	$argz = @(
    'register-with',
    '--console',
    '--instance', 'Tentacle',
	'--publicHostName', $publicHostName,
	'--server', $ServerUrl,
	'--force')
	
	if(!($ServerApiKey -eq $null)) {
		Write-Verbose "Registering Tentacle with api key"
		$argz += "--apiKey";
		$argz += $ServerApiKey
	} else {
		Write-Verbose "Registering Tentacle with username/password"
		$argz += "--username";
		$argz += $ServerUsername
		$argz += "--password";
		$argz += $ServerPassword
	}
	
	if($env:TargetName -ne $null) {
		$argz += "--name";
		$argz += $env:TargetName;
	}
		
	$TargetEnvironment.Split(",") | ForEach { 
		$argz += '--environment'; 
		$argz += $_.Trim();
	 };
	 
	 $TargetRole.Split(",") | ForEach { 
		$argz += '--role'; 
		$argz += $_.Trim();
	 };

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