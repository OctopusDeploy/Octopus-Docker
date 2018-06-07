#[System.Environment]::SetEnvironmentVariable("OCTOPUS_VERSION", "", [System.EnvironmentVariableTarget]::Machine);
$env:OCTOPUS_INSTANCENAME = "OctopusTentacle"
[System.Environment]::SetEnvironmentVariable("OCTOPUS_INSTANCENAME", $env:OCTOPUS_INSTANCENAME, [System.EnvironmentVariableTarget]::User);

. ./1-GetDsc.ps1
. ./2-DSC.ps1

#docker run -i --rm --env sqlDbConnectionString="Server=172.23.192.1,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=Password01!;MultipleActiveResultSets=False;Connection Timeout=30;" octopusdeploy/octopusdeploy