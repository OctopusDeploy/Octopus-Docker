#[System.Environment]::SetEnvironmentVariable("OCTOPUS_VERSION", "", [System.EnvironmentVariableTarget]::Machine);
$env:OCTOPUS_INSTANCENAME = "OctopusServer"
[System.Environment]::SetEnvironmentVariable("OCTOPUS_INSTANCENAME", $env:OCTOPUS_INSTANCENAME, [System.EnvironmentVariableTarget]::User);


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not (Test-Path "C:\Program Files\WindowsPowerShell\Modules\OctopusDSC")) {
    mkdir c:\temp -ErrorAction SilentlyContinue | Out-Null
    $client = new-object system.Net.Webclient
    $client.DownloadFile("https://github.com/OctopusDeploy/OctopusDSC/archive/master.zip","c:\temp\octopusdsc.zip")
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("c:\temp\octopusdsc.zip", "c:\temp")
    cp -Recurse C:\temp\OctopusDSC-master\OctopusDSC "C:\Program Files\WindowsPowerShell\Modules\OctopusDSC"
}


. ./2-DSC.ps1

#docker run -i --rm --env sqlDbConnectionString="Server=172.23.192.1,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Password01!;MultipleActiveResultSets=False;Connection Timeout=30;" octopusdeploy/octopusdeploy