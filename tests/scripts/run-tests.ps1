param (
  [Parameter(Mandatory=$True)]
  [string]$testfile
)

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12,[System.Net.SecurityProtocolType]::Tls11,[System.Net.SecurityProtocolType]::Tls

# If for whatever reason this doesn't work, check this file:
Start-Transcript -path "C:\run-octopus-docker-tests.txt" -append

function Install-Chocolatey {
  echo "##teamcity[blockOpened name='Installing Chocolatey']"

  write-output "Installing Chocolatey"
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "##teamcity[blockClosed name='Installing Chocolatey']"
}

function Install-Ruby {
  echo "##teamcity[blockOpened name='Install Ruby']"

  choco install ruby --version 2.3.3 --allow-empty-checksums --yes --no-progress
  if ($LASTEXITCODE -ne 0) {
    write-host "'choco install ruby --version 2.3.3' failed with with exit code $LASTEXITCODE"
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
  $octopusAdminUsername="admin"
  $octopusAdminPassword="Passw0rd123"

  if (Test-Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll") {
    $OctopusURI = "http://localhost:81"
    $ApiKeyName = "Docker Octopus Server Testing - $([guid]::NewGuid())"
    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Client.dll"
  }
  else {
    $OctopusURI = "http://octopus:81"
    $ApiKeyName = "Docker Tentacle Testing - $([guid]::NewGuid())"
    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Tentacle\Newtonsoft.Json.dll"
    Add-Type -Path "${env:ProgramFiles}\Octopus Deploy\Tentacle\Octopus.Client.dll"
  }

  Write-host "Signing into Octopus server at $OctopusURI"
  #connect
  $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
  $repository = new-object Octopus.Client.OctopusRepository $endpoint

  #sign in
  $credentials = New-Object Octopus.Client.Model.LoginCommand
  $credentials.Username = $octopusAdminUsername
  $credentials.Password = $octopusAdminPassword
  $repository.Users.SignIn($credentials)

  #create the api key
  $user = $repository.Users.GetCurrent()
  $apiKeys = $repository.Users.GetApiKeys($user)
  Write-Host "Creating a new api key"
  $apiKey = $repository.Users.CreateApiKey($user, $ApiKeyName)

  Write-Host "Setting environment variables for use in tests"
  #save it to enviornment variables for tests to use
  $env:OctopusServerUrl = $OctopusURI
  $env:OctopusApiKey = $apiKey.ApiKey
}

try
{
  Install-Chocolatey
  Install-Ruby
  Install-ServerSpec
  Install-Gems
  Set-OctopusServerConfiguration

  C:/tools/ruby23/bin/bundle.bat _1.14.4_ exec rspec $testfile --format documentation
  exit $LASTEXITCODE
}
catch
{
  Write-Output $_
  exit 1
}
