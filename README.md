> You are looking at the README for the master branch of this gem.
> The latest released version lives in the stable-04 branch,
> [see here](https://github.com/influxdata/influxdb-rails/tree/stable-04#readme)
> for an online version.

# influxdb-rails

[![Gem Version](https://badge.fury.io/rb/influxdb-rails.svg)](https://badge.fury.io/rb/influxdb-rails)
[![Build Status](https://travis-ci.org/influxdata/influxdb-rails.svg?branch=master)](https://travis-ci.org/influxdata/influxdb-rails)

Automatically instrument your Ruby on Rails applications and write the
metrics directly into [InfluxDB](http://influxdb.org/).

This gem is designed for Rails 4.2+, Ruby 2.3+ and InfluxDB 0.9+.


## Installation

```
$ [sudo] gem install influxdb-rails
```

Or add it to your `Gemfile`, etc.


## Usage

To get things set up, just create an initializer:

```
$ cd /to/you/rails/application
$ touch config/initializers/influxdb_rails.rb
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

  # config.tags_middleware = ->(tags) { tags }

  # config.series_name_for_controller_runtimes = "rails.controller"
  # config.series_name_for_view_runtimes       = "rails.view"
  # config.series_name_for_db_runtimes         = "rails.db"
  # config.series_name_for_render_template     = "rails.render_template"
  # config.series_name_for_render_partial      = "rails.render_partial"
  # config.series_name_for_render_collection   = "rails.render_collection"
  # config.series_name_for_sql                 = nil
  # config.series_name_for_exceptions          = "rails.exceptions"
  # config.series_name_for_instrumentation     = "instrumentation"

  # Set the application name to something meaningful, by default we
  # infer the app name from the Rails.application class name.
  # config.application_name = Rails.application.class.parent_name
end
```

To see all default values, take a look into `InfluxDB::Rails::Configuration::DEFAULTS`,
defined in `lib/influxdb/rails/configuration.rb`

Out of the box, you'll automatically get reporting of your controller,
view, and db runtimes and rendering of template, partial and collection for each request.
Reporting of SQL queries is disabled by default because it is still in experimental mode
and currently requires String parsing which might cause performance issues on query
intensive applications. You can enable it by setting the `series_name_for_sql`
configuration.

It is possible to disable the rendering series by setting the series_name to nil.

```ruby
  # config.series_name_for_render_template     = nil
  # config.series_name_for_render_partial      = nil
  # config.series_name_for_render_collection   = nil
```

You can also call through to the underlying `InfluxDB::Client` object to write arbitrary data.
If you do that, it might be usefull to add the current context to these custom data points which can get
accessed with ``InfluxDB::Rails.current.location``.


``` ruby
InfluxDB::Rails.client.write_point "events",
  tags:   { url: "/foo", user_id: current_user.id, location: InfluxDB::Rails.current.location },
  values: { value: 0 }
```

Additional documentation for `InfluxDB::Client` lives in the
[influxdb-ruby](http://github.com/influxdata/influxdb-ruby) repo.


### Tags

You can modify the tags sent to InfluxDB by defining a middleware, which
receives the current tag set (`Hash` with `Symbol` keys and `String`
values) as argument and returns a hash in the same form. The middleware
can be any object, as long it responds to `#call` (like a `Proc`):

```ruby
InfluxDB::Rails.configure do |config|
  config.tags_middleware = lambda do |tags|
    tags.merge(env: Rails.env)
  end
end
```

If you want to add dynamically tags per request, you can access the ``InfluxDB::Rails.current.tags`` to
do so. For instance, you could add the current user as tag to every data point.

```ruby
class ApplicationController

  before_action :set_influx_tags

  def set_influx_tags
    InfluxDB::Rails.current.tags = { user: current_user.id }
  end
end

```

By default, the following tags are sent for *non-exception series*
(`rails.controller`, `rails.view`, `rails.db` and `instrumentation`):

```ruby
{
  method:      "#{payload[:controller]}##{payload[:action]}",
  server:      Socket.gethostname,
  app_name:    configuration.application_name,
  http_method: payload[:method],
  format:      payload[:format],
  status:      payload[:status]
}
```
For the render series (``rails.render_partial``, ``rails.render_view`` and ``rails.render_collection``)

```ruby
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "#{payload[:controller]}##{payload[:action]}",
  filename:   payload[:identifier],
  count:      payload[:count],
  cache_hits: payload[:cache_hits],
```

For the SQL series (``rails.sql``, disabled by default)

```ruby
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "#{payload[:controller]}##{payload[:action]}",,
  operation:  "SELECT",
  class_name: "USER",
  name:       payload[:name],
```

For more information about the payload, have a look at the [official ActiveSupport documentation](https://guides.rubyonrails.org/active_support_instrumentation.html#process-action-action-controller).


For the exceptions (series name `rails.exceptions`):

```ruby
{
  application_name:   InfluxDB::Rails.configuration.application_name,
  application_root:   InfluxDB::Rails.configuration.application_root,
  framework:          InfluxDB::Rails.configuration.framework,
  framework_version:  InfluxDB::Rails.configuration.framework_version,
  language:           "Ruby",
  language_version:   "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
  custom_data:        @custom_data,
  class:              @exception.class.to_s,
  method:             "#{@controller}##{@action}",
  filename:           File.basename(@backtrace.lines.first.try(:file)),
  server:             Socket.gethostname,
  status:             "open",
}
```


## Frequently Asked Questions


**Q: I'm seeing far less requests recorded in InfluxDB than my logs suggest.**

By default, this gem only sends data points with *second time precision*
to the InfluxDB server. If you experience multiple requests per second,
**only the last** point (with the same tag set) is stored.

See [InfluxDB server docs][duplicate-points] for further details.
To work around this limitation, set the `config.time_precision` to one
of `"ms"` (milliseconds, 1·10<sup>-3</sup>s), `"us"` (microseconds,
1·10<sup>-6</sup>s) or `"ns"` (nanoseconds, 1·10<sup>-9</sup>s).

[duplicate-points]: https://docs.influxdata.com/influxdb/v1.4/troubleshooting/frequently-asked-questions/#how-does-influxdb-handle-duplicate-points


**Q: How does the measurement influence the response time?**

This gem subscribes to the `process_action.action_controller` controller
notification (via `ActiveSupport::Notifications` · [guide][arn-guide] ·
[docs][arn-docs] · [impl][arn-impl]), i.e. it runs *after* a controller
action has finished.

The thread processing incoming HTTP requests however is blocked until
the notification is processed. By default, this means calculating and
enqueueing some data points for later processing (`config.async = true`),
which usually is negligible. The asynchronuous sending happens in a seperate
thread, which batches multiple data points.

If you, however, use a synchronous client (`config.async = false`), the
data points are immediately sent to the InfluxDB server. Depending on
the network link, this might cause the HTTP thread to block a lot longer.

[arn-guide]: http://guides.rubyonrails.org/v5.1/active_support_instrumentation.html#process-action-action-controller
[arn-docs]: http://api.rubyonrails.org/v5.1/classes/ActiveSupport/Notifications.html
[arn-impl]: https://github.com/rails/rails/blob/5-1-stable/actionpack/lib/action_controller/metal/instrumentation.rb#L30-L38


**Q: How does this gem handle an unreachable InfluxDB server?**

By default, the InfluxDB client will retry indefinetly, until a write
succeedes (see [client docs][] for details). This has two important
implcations, depending on the value of `config.async`:

- if the client runs asynchronously (i.e. in a seperate thread), the queue
  might fill up with hundrets of megabytes of data points
- if the client runs synchronously (i.e. inline in the request/response
  cycle), it might block all available request threads

In both cases, your application server might become inresponsive and needs
to be restarted (which can happen automatically in `cgroups` contexts).

If you setup a maximum retry value (`Integer === config.retry`), the
client will try upto that amount of times to send the data to the server
and (on final error) log an error and discard the values.

[client docs]: https://github.com/influxdata/influxdb-ruby#retry


**Q: What happens with unwritten points, when the application restarts?**

The data points are simply discarded.


**Q: What happens, when the InfluxDB client or this gem throws an exception? Will the user see 500 errors?**

No. The controller instrumentation is wrapped in a `rescue StandardError`
clause, i.e. this gem will only write the error to the `client.logger`
(`Rails.logger` by default) and not disturb the user experience.


## Testing

```
git clone git@github.com:influxdata/influxdb-rails.git
cd influxdb-rails
bundle
bundle exec rake
```


## Contributing

- Fork this repository on GitHub.
- Make your changes.
  - Add tests.
  - Add an entry in the `CHANGELOG.md` in the "unreleased" section on top.
- Run the tests:
  - Either run them manually:
    ```console
    $ rake test:all
    ```
  - or wait for [Travis][travis-pr] to pick up your changes, *after*
    you made a pull request.
- Send a pull request.
  - Please rebase against the master branch.
- If your changes look good, we'll merge them.

[travis-pr]: https://travis-ci.org/influxdata/influxdb-rails/pull_requests
