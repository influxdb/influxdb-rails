# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "influxdb/rails/version"

Gem::Specification.new do |s|
  s.name        = "influxdb-rails"
  s.version     = InfluxDB::Rails::VERSION
  s.authors     = ["Todd Persen"]
  s.email       = ["todd@influxdb.com"]
  s.homepage    = "http://influxdb.com"
  s.summary     = %q{InfluxDB bindings for Ruby on Rails.}
  s.description = %q{This gem automatically instruments your Ruby on Rails 3.x/4.x applications using InfluxDB for storage.}

  s.rubyforge_project = "influxdb-rails"

  s.files         = Dir.glob('**/*')
  s.test_files    = Dir.glob('test/**/*') + Dir.glob('spec/**/*') + Dir.glob('features/**/*')
  s.executables   = Dir.glob('bin/**/*').map {|f| File.basename(f)}
  s.require_paths = ["lib"]

  s.licenses = ['MIT']

  s.add_runtime_dependency 'influxdb', '~> 0.3.0'
  s.add_runtime_dependency 'railties'

  s.add_development_dependency 'bundler', ['>= 1.0.0']
  s.add_development_dependency 'fakeweb', ['>= 0']
  s.add_development_dependency 'rake', ['>= 0']
  s.add_development_dependency 'rdoc', ['>= 0']
  s.add_development_dependency 'rspec', ['>= 0']
  s.add_development_dependency 'rspec-rails', ['>= 3.0.0']
  s.add_development_dependency 'tzinfo', ['>= 0']
end
