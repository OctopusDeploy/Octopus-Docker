param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusDBContainer=$ProjectName+"_db_1";

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
$OctopusDeploySqlServerContainerHealth = ($(docker inspect $OctopusDBContainer) | ConvertFrom-Json).State.Health.Status

if ($OctopusDeploySqlServerContainerHealth -ne "healthy") {
  write-host "  - OctopusDeploySqlServer container is not healthy - health status is '$OctopusDeploySqlServerContainerHealth'. Aborting."
  exit 1
}
write-host "  - OctopusDeploySqlServer container is healthy"

write-host " Checking to make sure OctopusDeploy container is up and running"
$OctopusDeployContainerHealth = ($(docker inspect $OctopusServerContainer) | ConvertFrom-Json).State.Health.Status

if ($OctopusDeployContainerHealth -ne "healthy") {
  write-host "  - OctopusDeploy container is not healthy - health status is '$OctopusDeployContainerHealth'. Aborting."
  exit 2
}
write-host "  - OctopusDeploy container is healthy"

$OctopusContainerIpAddress = ($(docker inspect $OctopusServerContainer) | ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress
if (($OctopusContainerIpAddress -eq $null) -or ($OctopusContainerIpAddress -eq "")) {
    write-host " OctopusDeploy Container does not exist. Aborting."
    exit 3
}

write-host "-----------------------------------"
write-host "Debugging:"
write-host "-----------------------------------"
write-host "docker logs OctopusDeploySqlServer:"
& docker logs $OctopusDBContainer
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "-----------------------------------"
write-host "docker inspect OctopusDeploySqlServer:"
& docker inspect $OctopusDBContainer
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "-----------------------------------"
write-host "docker logs OctopusDeploy:"
& docker logs $OctopusServerContainer
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "-----------------------------------"
write-host "docker inspect OctopusDeploy:"
& docker inspect $OctopusServerContainer
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

function Copy-FileToDockerContainer($sourceFile, $destFile) {
  # docker cp only appears to work if you're copying from a drive thats shared (or something weird like that)
  write-host "Copying $sourceFile"
  $content = get-content $sourceFile -raw
  $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
  & docker exec $OctopusServerContainer cmd /c echo $encodedContent `> "$destFile.b64"
  $result = Execute-Command "docker" "exec $OctopusServerContainer powershell -command `$content = gc $destFile.b64; `$decoded = [System.Convert]::FromBase64String(`$content); Set-Content -Path $destFile -Value `$decoded -encoding byte"
  if ($result.ExitCode -ne 0) {
    exit $result.ExitCode
  }
}

write-host "-----------------------------------"
write-host "Copying test files"
Copy-FileToDockerContainer "$PSScriptRoot/scripts/run-tests.ps1" "c:\run-tests.ps1"
Copy-FileToDockerContainer "$PSScriptRoot/scripts/octopus-server_spec.rb" "c:\octopus-server_spec.rb"
Copy-FileToDockerContainer "$PSScriptRoot/scripts/Gemfile" "c:\Gemfile"
Copy-FileToDockerContainer "$PSScriptRoot/scripts/Gemfile.lock" "c:\Gemfile.lock"
Copy-FileToDockerContainer "$PSScriptRoot/scripts/spec_helper.rb" "c:\spec_helper.rb"

write-host "-----------------------------------"
write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1"
if (Test-Path ENV:TEAMCITY_PROJECT_NAME) {
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusServerContainer powershell -file c:\run-tests.ps1
} else {
  & docker exec $OctopusServerContainer powershell -file c:\run-tests.ps1
}
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
write-host "-----------------------------------"
