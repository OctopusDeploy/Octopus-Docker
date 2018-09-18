require_relative 'spec_helper'

describe file('c:\Octopus') do
  it { should be_directory }
end

describe file('c:\applications') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Tentacle\\") }
end

describe port(10933) do
  it { should be_listening.with('tcp') }
end

describe octopus_deploy_tentacle(ENV['OctopusServerUrl'], ENV['OctopusApiKey'], "Tentacle") do
  it { should exist }
  it { should be_registered_with_the_server }
  it { should be_online }
  it { should be_listening_tentacle }
  it { should be_in_environment('Development') }
  it { should have_role('app-server') }
  it { should have_display_name(ENV['ComputerName']) }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle\Tentacle') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\Tentacle.config') }
end
