lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "influxdb/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "influxdb-rails"
  spec.version     = InfluxDB::Rails::VERSION
  spec.authors     = ["Dominik Menke", "Todd Persen"]
  spec.email       = ["dominik.menke@gmail.com", "todd@influxdb.com"]
  spec.homepage    = "https://influxdata.com"
  spec.summary     = "InfluxDB bindings for Ruby on Rails."
  spec.description = "This gem automatically instruments your Ruby on Rails" \
                     " 4.2/5.x applications using InfluxDB for storage."
  spec.licenses    = ["MIT"]

  spec.files         = `git ls-files`.split($/) # rubocop:disable Style/SpecialGlobalVars
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|smoke)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency "influxdb", "~> 0.5.0"
  spec.add_runtime_dependency "railties", "> 3"

  spec.add_development_dependency "bundler", ">= 1.0.0"
  spec.add_development_dependency "fakeweb"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails", ">= 3.0.0"
  spec.add_development_dependency "rubocop", "~> 0.60.0"
  spec.add_development_dependency "tzinfo"
end
