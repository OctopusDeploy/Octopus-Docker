param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

function Execute-Command ($commandPath, $commandArguments)
{
    Write-Host "Executing '$commandPath $commandArguments'"
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $pinfo.WorkingDirectory = $pwd
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    Write-Host $stdout
    Write-Host $stderr
    Write-Host "Process exited with exit code $($p.ExitCode)"

    [pscustomobject]@{
        stdout = $stdout
        stderr = $stderr
        ExitCode = $p.ExitCode
    }
}

write-host "------------"
write-host "docker --version"
write-host "------------"
& docker --version
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "------------"
write-host "docker version"
write-host "------------"
& docker version
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
write-host "------------"

# todo: check to make sure there is an msi in the "source" directory

$env:OCTOPUS_VERSION=$OctopusVersion
$result = Execute-Command "docker" "build --tag octopusdeploy/octopusdeploy-prerelease:$OctopusVersion --build-arg OctopusVersion=$OctopusVersion ."
if($result.ExitCode -ne 0){
     write-host "Docker failed with exit code " $result.ExitCode
    exit $result.ExitCode
}
$result = Execute-Command "docker-compose" "up --force-recreate -d"
if($result.ExitCode -ne 0){
     write-host "Docker failed with exit code " $result.ExitCode
    exit $result.ExitCode
}  

$docker = docker inspect octopusdocker_octopus_1 | convertfrom-json
Write-Host Server available from the host at http://$($docker[0].NetworkSettings.Networks.nat.IpAddress):81
