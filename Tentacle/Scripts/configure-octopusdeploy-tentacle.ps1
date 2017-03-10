[CmdletBinding()]
Param()

$OctopusServerApiKey = $env:OctopusServerApiKey;
$OctopusServerUrl = $env:OctopusServerUrl;
$OctopusTentaclePort = $env:OctopusTentaclePort;
$OctopusEnvironment = $env:OctopusEnvironment;
$MachineRoles = $env:MachineRoles;

if($OctopusServerApiKey -eq $null) {
	Write-Error "Missing api key. Provide OctopusServerApiKey environment variable"
	exit 1;
}

if($OctopusServerUrl -eq $null) {
	Write-Error "Missing api key. Provide OctopusServerUrl environment variable"
	exit 1;
}

if($OctopusTentaclePort -eq $null){
$OctopusTentaclePort = 10933;
}

if($OctopusEnvironment -eq $null){
$OctopusEnvironment = "Dev";
}
if($MachineRole -eq $null){
$MachineRole = "app-server, docker-container";
}


$OFS = "`r`n"


Install-Module "OctopusDSC"
echo "using PSModulePath: ${env:PSModulePath}"
echo ""
echo "Running Configuration file: ConfigureOctopusTentacle.ps1"

# Import the Manifest
cd $PSScriptRoot
. $PSScriptRoot\ConfigureOctopusTentacle.ps1
$StagingPath = $PSScriptRoot +"staging"


$Config = @{
    AllNodes =
    @(
        @{
          NodeName = "localhost";
          PSDscAllowPlainTextPassword = $true;
          RebootIfNeeded = $True;
        }
    )
};


ConfigureOctopusTentacle `
	-OutputPath $StagingPath `
	-ConfigurationData $Config `
	-ApiKey $OctopusServerApiKey `
	-OctopusServerUrl $OctopusServerUrl `
	-Environments $OctopusEnvironment `
	-Roles $MachineRole `
	-ListenPort $OctopusTentaclePort

Start-DscConfiguration -Force -Wait -Verbose -Path $StagingPath
del $StagingPath\*.mof