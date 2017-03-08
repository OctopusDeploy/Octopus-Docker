[CmdletBinding()]
Param()

$OctopusServerApiKey = $env:OctopusServerApiKey;
$OctopusServerUrl = $env:OctopusServerUrl;
$OctopusTentaclePort = $env:OctopusTentaclePort;
$OctopusEnvironment = $env:OctopusEnvironment;
$MachineRoles = $env:MachineRoles;

#"http://master.octopushq.com"
#"API-BZ1RNCOBH312W0PKCP6OQ3UZL4"
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

$currDir = Split-Path $MyInvocation.MyCommand.Path
write-host "current working dir is $currDir"

Install-Module "OctopusDSC"
echo "using PSModulePath: ${env:PSModulePath}"
echo ""
echo "Running Configuration file: InstallOctopusTentacle.ps1"

# Import the Manifest
cd $currDir
. $currDir\InstallOctopusTentacle.ps1

$StagingPath = $currDir +"staging"
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
InstallOctopusTentacle -OutputPath $StagingPath `
	-ConfigurationData $Config `
	-ApiKey $OctopusServerApiKey `
	-OctopusServerUrl $OctopusServerUrl `
	-Environments $OctopusEnvironment `
	-Roles $MachineRole `
	-ListenPort $OctopusTentaclePort

# Start a DSC Configuration run
Start-DscConfiguration -Force -Wait -Verbose -Path $StagingPath
del $StagingPath\*.mof