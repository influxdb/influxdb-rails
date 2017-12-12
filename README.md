# influxdb-rails

> This library is now updated to require `influxdb-ruby` v0.2.0 and greater,
> meaning that only InfluxDB v0.9.x and higher will be supported.  **If
> you want to use this library with InfluxDB v0.8.x, you'll need to use
> v0.1.10 or earlier. You will also need to manually specify
> `gem 'influxdb', '0.1.9'` in your gemfile.**

We encourage you to submit a pull request if you have a contribution.
Maintained by [@toddboom][] and [@dmke][].

[@toddboom]: https://github.com/toddboom
[@dmke]: https://github.com/dmke

---

[![Gem Version](https://badge.fury.io/rb/influxdb-rails.svg)](https://badge.fury.io/rb/influxdb-rails)
[![Build Status](https://travis-ci.org/influxdata/influxdb-rails.svg?branch=master)](https://travis-ci.org/influxdata/influxdb-rails)

Automatically instrument your Ruby on Rails applications and write the
metrics directly into [InfluxDB](http://influxdb.org/).

## Install

```
$ [sudo] gem install influxdb-rails
```

Or add it to your `Gemfile`, etc.

## Usage

To get things set up, just create an initializer:

```
$ cd /to/you/rails/application
$ touch config/initializers/influxdb-rails.rb
```

In this file, you can configure the `InfluxDB::Rails` adapter. The default
config should look something like this:

``` ruby
InfluxDB::Rails.configure do |config|
  config.influxdb_database = "rails"
  config.influxdb_username = "root"
  config.influxdb_password = "root"
  config.influxdb_hosts    = ["localhost"]
  config.influxdb_port     = 8086

  # config.retry = false
  # config.async = false
  # config.open_timeout = 5
  # config.read_timeout = 30
  # config.max_delay = 300
  # config.time_precision = 'ms'

  # config.series_name_for_controller_runtimes = "rails.controller"
  # config.series_name_for_view_runtimes       = "rails.view"
  # config.series_name_for_db_runtimes         = "rails.db"
end
```

Out of the box, you'll automatically get reporting of your controller,
view, and db runtimes for each request. You can also call through to the
underlying `InfluxDB::Client` object to write arbitrary data like this:

``` ruby
InfluxDB::Rails.client.write_point "events",
  tags:   { url: "/foo", user_id: current_user.id },
  values: { value: 0 }
```

Additional documentation for `InfluxDB::Client` lives in the
[influxdb-ruby](http://github.com/influxdb/influxdb-ruby) repo.
