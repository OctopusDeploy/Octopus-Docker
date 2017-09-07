$OFS = "`r`n";

function Execute-Command ($commandPath, $commandArguments) {
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

function Docker-Login() {
  write-host "docker login -u=`"$UserName`" -p=`"#########`""
  & docker login -u="$UserName" -p="$Password"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Push-Image() {
  param (
    [Parameter(Mandatory=$true)]
    [string] $ImageName
  )

  write-host "docker push $ImageName"
  & docker push $ImageName
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Start-DockerCompose($ProjectName) {
  $PrevExitCode = -1;
  $attempts=5;

  while ($true -and $PrevExitCode -ne 0) {
    if($attempts-- -lt 0){
      & docker-compose --project-name $ProjectName logs
      write-host "Ran out of attempts to create container.";
      exit 1
    }

    write-host "docker-compose --project-name $ProjectName --file .\docker-compose.yml up --force-recreate -d"
    & docker-compose --project-name $ProjectName --file .\docker-compose.yml up --force-recreate -d

    $PrevExitCode = $LASTEXITCODE
    if($PrevExitCode -ne 0) {
      Write-Host $Error
      Write-Host "docker-compose failed with exit code $PrevExitCode";
      & docker-compose --project-name $ProjectName --file .\docker-compose.yml logs
    }
  }
}

function Wait-ForServiceToPassHealthCheck($serviceName) {
  $attempts = 0;
  $sleepsecs = 5;
  While($attempts -lt 20)
  {
    $attempts++
    $health = ($(docker inspect $serviceName) | ConvertFrom-Json).State.Health.Status;
    Write-Host "Waiting for $serviceName to be healthy (current: $health)..."
    if ($health -eq "healthy"){
      break;
    }
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
    Sleep -Seconds $sleepsecs
  }
  if ((($(docker inspect $serviceName) | ConvertFrom-Json).State.Health.Status) -ne "healthy"){
    Write-Error "Octopus container $serviceName failed to go healthy after $($attempts * $sleepsecs) seconds";
    exit 1;
  }
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

function Test-RunningUnderTeamCity() {
  return Test-Path ENV:TEAMCITY_PROJECT_NAME
}

function Start-TeamCityBlock($name) {
  if (Test-RunningUnderTeamCity) {
    write-host "##teamcity[blockOpened name='$name']"
  }
}

function Stop-TeamCityBlock($name) {
  if (Test-RunningUnderTeamCity) {
    write-host "##teamcity[blockClosed name='$name']"
  }
}

function Write-DebugInfo($containerNames) {
  Start-TeamCityBlock "Debugging"

  write-host "-----------------------------------"
  write-host "Debugging:"

  foreach($containerName in $containerNames) {
    Start-TeamCityBlock "docker logs $containerName"
    write-host "-----------------------------------"
    write-host "docker logs $containerName:"
    & docker logs $containerName
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
    Stop-TeamCityBlock "docker logs $containerName"

    Start-TeamCityBlock "docker inspect $containerName"
    write-host "-----------------------------------"
    write-host "docker inspect $containerName:"
    & docker inspect $containerName
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
    Stop-TeamCityBlock "docker inspect $containerName"
  }

  if (Test-RunningUnderTeamCity) { write-host "##teamcity[blockClosed name='Debugging']"}

}

function Check-IPAddress() {
  $OctopusContainerIpAddress = ($(docker inspect $OctopusServerContainer) | ConvertFrom-Json).NetworkSettings.Networks.nat.IpAddress
  if (($OctopusContainerIpAddress -eq $null) -or ($OctopusContainerIpAddress -eq "")) {
    write-host " OctopusDeploy Container does not exist. Aborting."
    exit 3
  }
}
