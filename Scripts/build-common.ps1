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

function Start-DockerCompose($projectName, $composeFile) {
  $PrevExitCode = -1;
  $attempts=5;

  while ($true -and $PrevExitCode -ne 0) {
    if($attempts-- -lt 0){
      & docker-compose --project-name $projectName logs
      write-host "Ran out of attempts to create container.";
      exit 1
    }

    write-host "docker-compose --project-name $projectName --file $composeFile up --force-recreate -d"
    & docker-compose --project-name $projectName --file $composeFile up --force-recreate -d

    $PrevExitCode = $LASTEXITCODE
    if($PrevExitCode -ne 0) {
      Write-Host $Error
      Write-Host "docker-compose failed with exit code $PrevExitCode";
      & docker-compose --project-name $projectName --file $composeFile logs
    }
  }
}

function Wait-ForServiceToPassHealthCheck($serviceName) {
  $attempts = 0;
  $sleepsecs = 10;
  while ($attempts -lt 30)
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
    Write-DebugInfo @($serviceName)
    Write-Error "Octopus container $serviceName failed to go healthy after $($attempts * $sleepsecs) seconds";
    exit 1;
  }
}

function Copy-FileToDockerContainer($sourceFile, $destFile, $container) {
  # docker cp only appears to work if you're copying from a drive thats shared (or something weird like that)
  write-host "Copying $sourceFile"
  $content = get-content $sourceFile -raw
  write-host " - file is $($content.length) characters"
  $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
  write-host " - base 64 encoded file is $($encodedContent.length) characters"
  $currentPosition = 0
  # kill existing file if it exists
  write-host " - creating initial file $destFile.b64"
  & docker exec $container powershell -command "set-content -path $destFile.b64 -value ''"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  while ($currentPosition -lt $encodedContent.length) {
    $length = (1000, ($encodedContent.length - $currentPosition) | Measure -Minimum).Minimum
    write-host " - sending partial file, $length characters starting from $currentPosition"
    $text = $encodedContent.Substring($currentPosition, $length)
    & docker exec $container cmd /c echo $text `>> "$destFile.b64"
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
    $currentPosition = $currentPosition + 1000
  }

  write-host " - decoding partial file from $destFile.b64 tp $destFile"
  $result = Execute-Command "docker" "exec $container powershell -command `$content = gc $destFile.b64; `$decoded = [System.Convert]::FromBase64String(`$content); Set-Content -Path $destFile -Value `$decoded -encoding byte"

  if ($result.ExitCode -ne 0) {
    exit $result.ExitCode
  }
}

function Copy-FilesToDockerContainer($sourcePath, $container) {

  Start-TeamCityBlock "Copy test files to $container"

  foreach($file in gci $sourcePath -file) {
    $fileName = Split-Path $file -Leaf
    Copy-FileToDockerContainer $file.FullName "c:\$fileName" $container
  }

  Stop-TeamCityBlock "Copy test files to $container"
}

function Test-RunningUnderTeamCity() {
  return Test-Path ENV:TEAMCITY_PROJECT_NAME
}

function Start-TeamCityBlock($name) {
  if (Test-RunningUnderTeamCity) {
    write-host "##teamcity[blockOpened name='$name']"
  } else {
    write-host "-----------------------------------"
    write-host $name
    write-host "-----------------------------------"
  }
}

function Stop-TeamCityBlock($name) {
  if (Test-RunningUnderTeamCity) {
    write-host "##teamcity[blockClosed name='$name']"
  } else {
    write-host "-----------------------------------"
  }
}

function Write-DebugInfo($containerNames) {
  Start-TeamCityBlock "Debug Info"

  foreach($containerName in $containerNames) {
    Start-TeamCityBlock "docker logs $containerName"
    & docker logs $containerName
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
    Stop-TeamCityBlock "docker logs $containerName"

    Start-TeamCityBlock "docker inspect $containerName"
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

function Confirm-RunningFromRootDirectory {
  $childFolders = Get-ChildItem -Directory | split-Path -Leaf
  if ((-not ($childFolders -contains "Tentacle")) -or (-not ($childFolders -contains "Server"))) {
    write-host "This script needs to be run from the root of the repo"
    exit 5
  }
}
