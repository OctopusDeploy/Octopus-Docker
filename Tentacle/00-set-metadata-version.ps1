param (
    [Parameter(Mandatory=$false)]
    [string]$OctopusVersion="latest"
)

. ./Scripts/build-common.ps1

function DetermineActualServerVersion($version){

    $dockerImage = "octopusdeploy/octopusdeploy:$version"
    $searchFor = "OctopusVersion=";

    if ("latest" -eq $version){
        & docker image pull -q $dockerImage > $null
        $json = (& docker image inspect octopusdeploy/octopusdeploy:$version | convertfrom-json)
        $envVarString = $json[0].ContainerConfig.Env | Where-Object { $_ -like "$searchFor*" } | Select-Object -First 1

    if ($null -eq $envVarString){
        return $null
    }

        return $envVarString.Substring($searchFor.Length)

    } else {
        return $version;
    }
}

TeamCity-Block("Setting metadata version") {
    $actualVersion = DetermineActualServerVersion($OctopusVersion)

    if ($null -eq $actualVersion){
        write-host "Could not determine the actual version of Octopus Server."
    } else {
        write-host "Determined version of Octopus Server to be: $actualVersion"

        $filePath = './Testing/Import/metadata.json'
        ((Get-Content -path $filePath -Raw) -replace '"DatabaseVersion": "0.0.0"', ('"DatabaseVersion": "'+$actualVersion+'"')) | Set-Content -Path $filePath   
    }
}