require "rails/generators"

class InfluxdbGenerator < Rails::Generators::Base # rubocop:disable Style/Documentation
  desc "Description:\n  This creates a Rails initializer for InfluxDB::Rails."

  source_root File.expand_path("templates", __dir__)

  def copy_initializer_file
    template "initializer.rb", "config/initializers/influxdb_rails.rb"
  end

  def install
    # nothing to do here
  end
end
