param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

Add-Type -Path './Testing/Tools/Octopus.Client.dll'

TeamCity-Block("Run tests") {

    $OctopusServerContainer=$ProjectName+"_octopus_1";
    $OctopusDBContainer=$ProjectName+"_db_1";

    Wait-ForServiceToPassHealthCheck $OctopusDBContainer
    Wait-ForServiceToPassHealthCheck $OctopusServerContainer

    Check-IPAddress

    Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)

    TeamCity-Block("Pester testing") {        
		
      $TestResult = Invoke-Pester -PassThru -Script @{ Path = './Server/Tests/*'; Parameters = @{ IPAddress = $(Get-IPAddress); OctopusUsername="admin"; OctopusPassword="Passw0rd123"; OctopusVersion=$OctopusVersion }} -OutputFile ./Temp/Server-Test.xml -OutputFormat NUnitXml

      if($TestResult.FailedCount -ne 0) {
        Write-Host "Failed $($TestResult.FailedCount)/$($TestResult.TotalCount) Tests"
        exit 1
      } else {
        Write-Host "All $($TestResult.TotalCount) Tests Passed";
      }
    }

}