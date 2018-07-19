param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion
)
$OctopusVersion="2018.6.1"
$TentacleVersion="3.22.0"

. ../Scripts/build-common.ps1

Add-Type -Path '../Tools/Octopus.Client.dll'

TeamCity-Block("Run tests") {

  $OctopusServerContainer=$ProjectName+"_octopus_1";
	$OctopusListeningTentacleContainer=$ProjectName+"_listeningtentacle_1";
	$OctopusPollingTentacleContainer=$ProjectName+"_pollingtentacle_1";
	$OctopusDBContainer=$ProjectName+"_db_1";

	#Wait-ForServiceToPassHealthCheck $OctopusDBContainer
	#Wait-ForServiceToPassHealthCheck $OctopusServerContainer
	#Wait-ForServiceToPassHealthCheck $OctopusListeningTentacleContainer
  #Wait-ForServiceToPassHealthCheck $OctopusPollingTentacleContainer
   
  Write-Host "Server Hosted at $(Get-IPAddress)"
    Check-IPAddress
    #Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer, $OctopusListeningTentacleContainer, $OctopusPollingTentacleContainer)

    #Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)
    
    TeamCity-Block("Pester testing") {
		$TestResult = Invoke-Pester -PassThru -Script @{ Path = './Tests/*.Tests.ps1'; Parameters = @{ IPAddress = $(Get-IPAddress); OctopusUsername="admin"; OctopusPassword="Passw0rd123"; OctopusVersion=$OctopusVersion; ProjectName=$ProjectName }} -OutputFile Test.xml -OutputFormat NUnitXml

		if($TestResult.FailedCount -ne 0) {
			Write-Host "Failed $($TestResult.FailedCount)/$($TestResult.TotalCount) Tests"
			Exit 1
		} else {
			Write-Host "All $($TestResult.TotalCount) Tests Passed";
		}
    }

}