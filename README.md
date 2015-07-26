influxdb-rails
==============


# This library is not updated for InfluxDB 0.9. There are breaking changes to the API, use at your own risk.

We encourage you to submit a pull request if you have a contribution. If you make a PR please explicitly call @beckettsean to get eyes on your PR.

----------



[![Build Status](https://travis-ci.org/influxdb/influxdb-rails.png?branch=master)](https://travis-ci.org/influxdb/influxdb-rails)

Auotmatically instrument your Ruby on Rails applications and write the metrics directly into [InfluxDB](http://influxdb.org/).

Install
-------

```
$ [sudo] gem install influxdb-rails
```

Or add it to your `Gemfile`, etc.

Usage
-----

To get things set up, just create an initializer:

```
$ rails g influxdb
```

Then, you can edit the file at `config/initializers/influxdb-rails.rb`. The default config should look something like this:

``` ruby
InfluxDB::Rails.configure do |config|
  config.influxdb_database = "rails"
  config.influxdb_username = "root"
  config.influxdb_password = "root"
  config.influxdb_hosts    = ["localhost"]
  config.influxdb_port     = 8086

  # config.series_name_for_controller_runtimes = "rails.controller"
  # config.series_name_for_view_runtimes       = "rails.view"
  # config.series_name_for_db_runtimes         = "rails.db"
  # config.series_name_for_status_codes        = "rails.status"
end
```

Out of the box, you'll automatically get reporting of your controller, view, and db runtimes for each request. You can also call through to the underlying `InfluxDB::Client` object to write arbitray data like this:

``` ruby
InfluxDB::Rails.client.write_point("events", {url: "/foo", user_id: current_user.id})
```

Additional documentation for `InfluxDB::Client` lives in the [influxdb-ruby](http://github.com/influxdb/influxdb-ruby) repo.
