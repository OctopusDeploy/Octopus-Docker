require 'serverspec'
require 'rspec/teamcity'
require 'octopus_serverspec_extensions'
require 'json_spec'

set :backend, :cmd
set :os, :family => 'windows'

RSpec.configure do |c|
  c.include JsonSpec::Helpers

  if (ENV['tc_project_name'] && !ENV['tc_project_name'].empty?) then
    c.add_formatter Spec::Runner::Formatter::TeamcityFormatter
  end
end
