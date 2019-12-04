param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$true)]
  [string]$OSVersion
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

function Get-BaseImage($OSVersion) {
    # Windows Container Compatability https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility
    # .NET Runtime images https://hub.docker.com/_/microsoft-dotnet-framework-runtime/
    # https://docs.microsoft.com/en-us/windows/release-information/
    if($OSVersion -eq "1809") {
        #ltsc2019 == 1809 (build 17763.652)
        return "mcr.microsoft.com/dotnet/framework/runtime:4.7.2-windowsservercore-ltsc2019"
    } elseif($OSVersion -eq "1607") {
        #ltsc2016 == 1607 (build 14393.3115)
        return "mcr.microsoft.com/dotnet/framework/runtime:4.7.2-windowsservercore-ltsc2016"
    } elseif($OSVersion -eq "1803" -or $OSVersion -eq "ltsc2016" -or $OSVersion -eq "ltsc2019") {
        # https://github.com/microsoft/dotnet-framework-docker/tree/master/4.7.2/runtime
        return "mcr.microsoft.com/dotnet/framework/runtime:4.7.2-windowsservercore-$OSVersion"
    } elseif($OSVersion -eq "1903" -or $OSVersion -eq "1909") {
        # 1903/1909 currently only provides 4.8 base image
        # https://github.com/microsoft/dotnet-framework-docker/tree/master/4.8/runtime
        return "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-$OSVersion"
    }
}

TeamCity-Block("Build") {
  $imageVersion = Get-ImageVersion $OctopusVersion $OSVersion
  Write-Host "Creating image with tag 'octopusdeploy/octopusdeploy-prerelease:$imageVersion'"
  $baseImage = Get-BaseImage $OSVersion

  docker build --pull --tag octopusdeploy/octopusdeploy-prerelease:$imageVersion --build-arg BASE_IMAGE=$baseImage --build-arg OctopusVersion=$OctopusVersion --file Server\Dockerfile .

  if($LastExitCode -ne 0) {
    $last = $LastExitCode
    Write-Host "Image failed to be created"
    exit $last
  } else {
    Write-Host "Image created"
  }
}