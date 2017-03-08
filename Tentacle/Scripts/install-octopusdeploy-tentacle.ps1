[CmdletBinding()]
Param()

$currDir = Split-Path $MyInvocation.MyCommand.Path
write-host "current working dir is $currDir"

Write-Host "Checking NuGet Package Provider is installed"
Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue -ErrorVariable NuGetError | Out-Null
if ($NuGetError) {
    Write-Host "Installing Package Provider Nuget"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
}
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
    Set-PSRepository -Name PSGallery -InstallationPolicy "Trusted"
}

