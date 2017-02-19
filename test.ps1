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

write-host "Checking to make sure Sql Server container is up and running"
$OctopusDeploySqlServerContainerHealth = ($(docker inspect OctopusDeploySqlServer) | ConvertFrom-Json).State.Health.Status

if ($OctopusDeploySqlServerContainerHealth -ne "healthy") {
  write-host "  - OctopusDeploySqlServer container is not healthy - health status is '$OctopusDeploySqlServerContainerHealth'. Aborting."
  exit 1
}
write-host "  - OctopusDeploySqlServer container is healthy"

write-host " Checking to make sure OctopusDeploy container is up and running"
$OctopusDeployContainerHealth = ($(docker inspect OctopusDeploy) | ConvertFrom-Json).State.Health.Status

if ($OctopusDeployContainerHealth -ne "healthy") {
  write-host "  - OctopusDeploy container is not healthy - health status is '%OctopusDeployContainerHealth%'. Aborting."
  exit 2
}
write-host "  - OctopusDeploy container is healthy"

$OctopusContainerIpAddress = ($(docker inspect OctopusDeploy) | ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress

if (($OctopusContainerIpAddress -eq $null) -or ($OctopusContainerIpAddress -eq "")) {
    write-host " OctopusDeploy Container does not exist. Aborting."
    exit 3
}

# write-host "-----------------------------------"
# write-host "Debugging:"
# write-host "-----------------------------------"
# write-host "docker logs OctopusDeploySqlServer:"
# & docker logs OctopusDeploySqlServer
# if ($LASTEXITCODE -ne 0) {
#   exit $LASTEXITCODE
# }

# write-host "-----------------------------------"
# write-host "docker inspect OctopusDeploySqlServer:"
# & docker inspect OctopusDeploySqlServer
# if ($LASTEXITCODE -ne 0) {
#   exit $LASTEXITCODE
# }

# write-host "-----------------------------------"
# write-host "docker logs OctopusDeploy:"
# & docker logs OctopusDeploy
# if ($LASTEXITCODE -ne 0) {
#   exit $LASTEXITCODE
# }

# write-host "-----------------------------------"
# write-host "docker inspect OctopusDeploy:"
# & docker inspect OctopusDeploy
# if ($LASTEXITCODE -ne 0) {
#   exit $LASTEXITCODE
# }

write-host "-----------------------------------"
write-host "Copying run-tests.ps1"
$content = get-content Scripts/run-tests.ps1 -raw
$encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
& docker exec OctopusDeploy cmd /c echo $encodedContent `> c:\run-tests.ps1.b64
$result = Execute-Command "docker" "exec OctopusDeploy powershell -command `$content = gc run-tests.ps1.b64; `$decoded = [System.Convert]::FromBase64String(`$content); Set-Content -Path c:\run-tests.ps1 -Value `$decoded -encoding byte"
if ($result.ExitCode -ne 0) {
  exit $result.ExitCode
}

write-host "-----------------------------------"
write-host "Copying octopus-server_spec.rb"
$content = get-content Scripts/octopus-server_spec.rb -raw
$encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
& docker exec OctopusDeploy cmd /c echo $encodedContent `> c:\octopus-server_spec.rb.b64
$result = Execute-Command "docker" "exec OctopusDeploy powershell -command `$content = gc octopus-server_spec.rb.b64; `$decoded = [System.Convert]::FromBase64String(`$content); Set-Content -Path c:\octopus-server_spec.rb -Value `$decoded -encoding byte"
if ($result.ExitCode -ne 0) {
  exit $result.ExitCode
}

write-host "-----------------------------------"
write-host "docker exec OctopusDeploy powershell -file /run-tests.ps1"
& docker exec OctopusDeploy powershell -file c:\run-tests.ps1
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
write-host "-----------------------------------"
