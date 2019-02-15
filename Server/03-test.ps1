param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion="2019.1.6",
  [Parameter(Mandatory=$false)]
  [string]$OSVersion="ltsc2016"
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

Add-Type -Path './Testing/Tools/Octopus.Client.dll'

TeamCity-Block("Run tests") {

    $OctopusServerContainer=$ProjectName+"_octopus_1";
    $OctopusDBContainer=$ProjectName+"_db_1";

    #Wait-ForServiceToPassHealthCheck $OctopusDBContainer
    #Wait-ForServiceToPassHealthCheck $OctopusServerContainer

    #Check-IPAddress

    #Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)

    TeamCity-Block("Pester testing") {        

    try {
      $TestResult = Invoke-Pester -PassThru -Script @{ Path = './Server/Tests/*'; Parameters = @{ `
        OctopusUsername="admin"; `
        OctopusPassword="Passw0rd123"; `
        OctopusVersion=$OctopusVersion; `
        ProjectName=$ProjectName; `
        OSVersion=$OSVersion}} `
        -OutputFile ./Temp/Server-Test.xml `
        -OutputFormat NUnitXml

      if($TestResult.FailedCount -ne 0) {
        Write-Error "Failed $($TestResult.FailedCount)/$($TestResult.TotalCount) Tests"
        exit 1
      } else {
        Write-Host "All $($TestResult.TotalCount) Tests Passed";
      }
    } catch
    {
      Write-Host $_
      Write-Error "Pester Testing Failed"
      exit 2
    }
  }
}