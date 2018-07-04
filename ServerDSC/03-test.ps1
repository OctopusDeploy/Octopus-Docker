param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ../Scripts/build-common.ps1

TeamCity-Block("Run tests") {

    $OctopusServerContainer=$ProjectName+"_octopus_1";
    $OctopusDBContainer=$ProjectName+"_db_1";

    Wait-ForServiceToPassHealthCheck $OctopusDBContainer
    Wait-ForServiceToPassHealthCheck $OctopusServerContainer

    Check-IPAddress

    Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)

    TeamCity-Block("Pester testing") {
        Invoke-Pester -Script @{ Path = './Tests/*'; Parameters = @{ IPAddress = $(Get-IPAddress); OctopusUsername="admin"; OctopusPassword="Passw0rd123" }} -OutputFile Test.xml -OutputFormat NUnitXml
    }

}