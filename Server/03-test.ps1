param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
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
    
      
      try {
      $TestResult = Invoke-Pester -PassThru -Script @{ Path = './Server/Tests/*'; Parameters = @{ `
        OctopusUsername="admin"; `
        OctopusPassword="Passw0rd123"; `
        OctopusVersion=$OctopusVersion; `
        OSVersion=$OSVersion}} -OutputFile ./Temp/Server-Test.xml -OutputFormat NUnitXml

      if($TestResult.FailedCount -ne 0) {
        Write-Host "Failed $($TestResult.FailedCount)/$($TestResult.TotalCount) Tests"
        exit 1
      } else {
        Write-Host "All $($TestResult.TotalCount) Tests Passed";
      }
    } catch
    {
      Write-Log $_
      Write-Host "Pester Testing Failed"
      exit 2
    }
  }
}



<#

```plaintext
docker run --name octopusdocker_octopus_1 --tt --interactive --publish 81:81 --env MasterKey="CxoInWkfTISVMsV9M1o1Lg==" --env sqlDbConnectionString="Server=db,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=N0tS3cr3t!;MultipleActiveResultSets=False;Connection Timeout=30;" octopusdeploy/octopusdeploy-prerelease:2018.8.0-1709
```

#>