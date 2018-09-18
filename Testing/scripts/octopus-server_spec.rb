require_relative 'spec_helper'

describe file('c:/Octopus') do
  it { should be_directory }
end

describe file('C:/Program Files/Octopus Deploy/Octopus/Octopus.Server.exe') do
  it { should be_file }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer') do
  it { should exist }
  it { should have_property_value('InstallLocation', :type_string, "C:\\Program Files\\Octopus Deploy\\Octopus\\") }
end

describe windows_registry_key('HKEY_LOCAL_MACHINE\Software\Octopus\OctopusServer\OctopusServer') do
  it { should exist }
  it { should have_property_value('ConfigurationFilePath', :type_string, 'C:\Octopus\OctopusServer.config') }
end

describe port(10943) do
  it { should be_listening.with('tcp') }
end

describe port(81) do
  it { should be_listening.with('tcp') }
end
