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
    write-host "docker-compose --project-name $projectName --file $composeFile up --force-recreate -d"
    docker-compose --project-name $projectName --file $composeFile up --force-recreate -d

    $PrevExitCode = $LASTEXITCODE
    if($PrevExitCode -ne 0) {
       Write-Host "docker-compose failed with exit code $PrevExitCode";
       docker-compose --project-name $projectName --file $composeFile logs
       EXIT $PrevExitCode
     }
}

function Wait-ForServiceToPassHealthCheck($serviceName) {
  $attempts = 0;
  $sleepsecs = 10;
  while ($attempts -lt 50)
  {
    $attempts++
    $state = ($(docker inspect $serviceName) | ConvertFrom-Json).State
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }

    $health = $state.Health.Status;
    Write-Host "Waiting for $serviceName to be healthy (current: $health)..."
    if ($health -eq "healthy"){
      break;
    }
    
    if($state.Status -eq "exited"){
      Write-Error "$serviceName appears to have already failed and exited."
      exit 1
    }

    Sleep -Seconds $sleepsecs
  }
  if ((($(docker inspect $serviceName) | ConvertFrom-Json).State.Health.Status) -ne "healthy"){
    Write-DebugInfo @($serviceName)
    Write-Error "Octopus container $serviceName failed to go healthy after $($attempts * $sleepsecs) seconds";
    exit 1;
  }
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
  if (($OctopusContainerIpAddress -eq $null) -or ($(Get-IPAddress) -eq "")) {
    write-host " OctopusDeploy Container does not exist. Aborting."
    exit 3
  }
}

function Get-IPAddress()  {
  param (
  [Parameter(Mandatory=$false)]
  [string]$container=$OctopusServerContainer)
    $docker = (docker inspect $container | convertfrom-json)[0]
    return $docker.NetworkSettings.Networks.nat.IpAddress
}

function Confirm-RunningFromRootDirectory {
  $childFolders = Get-ChildItem -Directory | split-Path -Leaf
  if ((-not ($childFolders -contains "Tentacle")) -and (-not ($childFolders -contains "Server"))) {
    write-host "This script needs to be run from the root of the repo"
    exit 5
  }
}

function Get-GitBranch {
  return & git rev-parse --abbrev-ref HEAD
}

function Get-ImageVersion ($version, $osversion) {
  $gitBranch = Get-GitBranch

  if ($version -like "*-*") {
    $imageVersion = "$version.$osversion"
  } else {
    $imageVersion = "$version-$osversion"
  }
  
  #if (Test-Path env:BUILD_NUMBER) {
    #$imageVersion = "$imageVersion.$($env:BUILD_NUMBER)"
  #}

  return $imageVersion
}



function TeamCity-Block
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $blockName,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    try
    {
        Start-TeamCityBlock $blockName
        . $ScriptBlock
    }
    finally
    {
      Stop-TeamCityBlock $blockName
    }
}