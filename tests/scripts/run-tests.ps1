[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls

# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\run-octopus-server-tests.txt" -append

function Install-Chocolatey {
  echo "##teamcity[blockOpened name='Installing Chocolatey']"

  write-output "Installing Chocolatey"
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Installing Chocolatey']"
}

function Install-Ruby {
  echo "##teamcity[blockOpened name='Install Ruby']"

  choco install ruby --allow-empty-checksums --yes
  if ($LASTEXITCODE -ne 0) {
    write-host "'choco install ruby' failed with with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }

  refreshenv
  if ($LASTEXITCODE -ne 0) {
    write-host "'refreshenv' failed with with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }

  if (-not (Test-Path "c:\temp")) {
    New-Item "C:\temp" -Type Directory | out-null
  }

  write-host "Downloading rubygems update"
  Invoke-WebRequest "https://rubygems.org/downloads/rubygems-update-2.6.7.gem" -outFile "C:\temp\rubygems-update-2.6.7.gem"
  & C:\tools\ruby23\bin\gem.cmd install --local C:\temp\rubygems-update-2.6.7.gem
  if ($LASTEXITCODE -ne 0) {
    write-host "'gem.cmd install --local C:\temp\rubygems-update-2.6.7.gem' failed with with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }
  & C:\tools\ruby23\bin\update_rubygems.bat --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) {
    write-host "'update_rubygems.bat' failed with with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }

  echo "##teamcity[blockClosed name='Install Ruby']"
}

function Install-ServerSpec {
  echo "##teamcity[blockOpened name='Install ServerSpec']"

  echo "running 'C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc'"
  & C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Install ServerSpec']"
}

function Install-Gems {
  echo "##teamcity[blockOpened name='Installing gem bundle']"

  & C:\tools\ruby23\bin\bundle.bat _1.14.4_ install --path=vendor --jobs 4
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Install gem bundle']"
}

function Set-OctopusServerConfiguration {
  $OctopusURI = "http://localhost:81"
  $octopusAdminUsername="admin"
  $octopusAdminPassword="Passw0rd123"

  Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
  Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"

  Write-host "Signing into Octopus server at $OctopusURI"
  #connect
  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
  $repository = new-object Octopus.Client.OctopusRepository $endpoint

  #sign in
  $credentials = New-Object Octopus.Client.Model.LoginCommand
  $credentials.Username = $octopusAdminUsername
  $credentials.Password = $octopusAdminPassword
  $repository.Users.SignIn($credentials)

  Write-Host "Checking if we need to create a new api key"
  #create the api key
  $user = $repository.Users.GetCurrent()
  $apiKeys = $repository.Users.GetApiKeys($user)
  Write-host "Existing api keys: [$($apiKeys.Purpose -join ', ')]"
  $apiKey = $apiKeys | where-object { $_.Purpose -eq "Docker Container Testing" }
  if ($null -eq $apiKey) {
    Write-Host "Creating a new api key"
    $apiKey = $repository.Users.CreateApiKey($user, "Docker Container Testing")
  } else {
    Write-Host "API Key already exists"
  }

  Write-Host "Setting environment variables for use in tests"
  #save it to enviornment variables for tests to use
  [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "User")
  [environment]::SetEnvironmentVariable("OctopusServerUrl", $OctopusURI, "Machine")
  [environment]::SetEnvironmentVariable("OctopusApiKey", $apiKey.ApiKey, "User")
  [environment]::SetEnvironmentVariable("OctopusApiKey", $apiKey.ApiKey, "Machine")
}

try
{
  Install-Chocolatey
  Install-Ruby
  Install-ServerSpec
  Install-Gems
  Set-OctopusServerConfiguration

  C:/tools/ruby23/bin/bundle.bat _1.14.4_ exec rspec octopus-server_spec.rb --format documentation
  exit $LASTEXITCODE
}
catch
{
  Write-Output $_
  exit 1
}
