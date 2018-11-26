$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
ENV["RAILS_ENV"] ||= "test"

require "rails"

if Rails::VERSION::MAJOR < 4 || Rails::VERSION::MAJOR == 4 && Rails::VERSION::MINOR < 2
  raise "Sorry, influxdb-rails only supports Rails 4.2 and higher."
end

require "bundler/setup"
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

puts "Loading Rails v#{Rails.version}..."

require "support/rails#{Rails::VERSION::MAJOR}/app"
require "rspec/rails"

RSpec.configure do |config|
  # use expect syntax
  config.disable_monkey_patching!

  # reset configuration for each spec
  config.before :each do
    InfluxDB::Rails.instance_variable_set :@configuration, nil
    InfluxDB::Rails.configure(&:load_rails_defaults)
  end
end
