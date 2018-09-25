param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion
)
$OctopusVersion="2018.8.0-dscserver"
$TentacleVersion="3.22.0"

. ./Scripts/build-common.ps1

Add-Type -Path './Testing/Tools/Octopus.Client.dll'

TeamCity-Block("Run tests") {

  $OctopusServerContainer=$ProjectName+"_octopus_1";
	$OctopusListeningTentacleContainer=$ProjectName+"_listeningtentacle_1";
	$OctopusPollingTentacleContainer=$ProjectName+"_pollingtentacle_1";
	$OctopusDBContainer=$ProjectName+"_db_1";

	Wait-ForServiceToPassHealthCheck $OctopusDBContainer
	Wait-ForServiceToPassHealthCheck $OctopusServerContainer
	Wait-ForServiceToPassHealthCheck $OctopusListeningTentacleContainer
  Wait-ForServiceToPassHealthCheck $OctopusPollingTentacleContainer
   
  Write-Host "Server Hosted at $(Get-IPAddress)"
	Check-IPAddress	
	TeamCity-Block("Pester testing") {
		$TestResult = Invoke-Pester -PassThru -Script @{ Path = './Tentacle/Tests/*.Tests.ps1'; Parameters = @{ `
			IPAddress = $(Get-IPAddress); `
			OctopusUsername="admin"; `
			OctopusPassword="Passw0rd123"; `
			OctopusVersion=$OctopusVersion; `
			ProjectName=$ProjectName }} `
			-OutputFile ./Temp/Tentacle-Test.xml `
			-OutputFormat NUnitXml

		if($TestResult.FailedCount -ne 0) {
			Write-Host "Failed $($TestResult.FailedCount)/$($TestResult.TotalCount) Tests"
			Exit 1
		} else {
			Write-Host "All $($TestResult.TotalCount) Tests Passed";
		}
	}
}