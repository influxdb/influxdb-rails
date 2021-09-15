# Changelog

For the full commit log, [see here](https://github.com/influxdata/influxdb-rails/commits/one-stable).

## v1.0.3, released 2021-09-15

- In case of unhandled exceptions, set status in measurements like Rails.logger does
- Require Ruby 2.5

## v1.0.2, released 2021-04-13

Fix passing booleans to custom tags.

## v1.0.1, released 2021-03-23

The final release, no code changes.

## v1.0.1.beta3, released 2020-10-16

- Drop `perform_start.active_job` subscriber, it's rather useless on dashboards.

## v1.0.1.beta2, released 2020-09-14

- Implement [`deliver.action_mailer`](https://guides.rubyonrails.org/active_support_instrumentation.html#deliver-action-mailer) subscriber
- Add missing Active Job documentation
- Drop support for Ruby 2.4
- Drop support for Rails < 5.2

## v1.0.1.beta1, released 2020-08-21

- Drop support for Ruby 2.3
- Drop support for Rails 4.x
- Add `auth_method` to client configuration (#96, @anlek)
- Drop undocumented `instrumentation_enabled` setting, use
  `ignored_environments` do disable instrumentation
- Simplified spec with a PORO test client
- Implement `instantiation.active_record` subscriber (https://guides.rubyonrails.org/active_support_instrumentation.html#instantiation-active-record)
- Implement `enqueue.active_job` subscriber (https://guides.rubyonrails.org/active_support_instrumentation.html#enqueue-active-job)
- Implement `perform_start.active_job` subscriber (https://guides.rubyonrails.org/active_support_instrumentation.html#perform-start-active-job)
- Implement `perform.active_job` subscriber (https://guides.rubyonrails.org/active_support_instrumentation.html#perform-active-job)
- Implement block instrumentation `InfluxDB::Rails.instrument do; 1 + 1; end`
- Record unhandled exceptions as tags for process_action.action_controller

## v1.0.0, released 2019-10-23

The Final release, no code changes.

## v1.0.0.beta5, unreleased

- Silently eat all dropped configuration options and do not crash
- Add per action view to the sample dashboard

## v1.0.0.beta4

- Introduces a Sample Grafana Dashboard + docker-compose demo (#75/#79, @hennevogel)
- Redesign Measurement Output (#66, @dmke, @ChrisBr, @hennevogel)
  - Switching from emitting eight different measurements to one called `rails`
    to support easier aggregation across data, to simplify configuration and to
    stay closer to the InfluxDB/Grafana nomenclature.
- Introduced configuration option `ignored_hooks` to disable specifc hooks
- Enable SQL subscriber by default
  - Set a default location (:raw) for SQL subscriber
- Add dynamic values (#65, @ChrisBr)
- Remove empty tags (#64, @ChrisBr)

## v1.0.0.beta3, released 2019-01-07

- Add dynamic tags (#62, @ChrisBr)
- Reduce cardinality of resulting InfluxDB measurement by moving
  some tags to values (#63, @ChrisBr)
- Remove SCHEMA queries from SQL instrumentation (#61, @ChrisBr)

## v1.0.0.beta2, released 2018-12-07

- Added `tags_middleware` config option (#47, @Kukunin)
- Removed path tag from metrics (introduced with #50), because it
  potentially produces "exceed tag value limit" (#54, @ChrisBr)
- Added render instrumentation (#53, @ChrisBr)
- Added SQL instrumentation (#55, @ChrisBr)

## v1.0.0.beta1, released 2018-11-22

- Added app name to the measurement's tag sets (#44, @stefanhorning)
- Added config parameters for additional series:
  - `InfluxDB::Rails::Configuration#series_name_for_instrumentation`
  - `InfluxDB::Rails::Configuration#series_name_for_exceptions`
- Added method, status and format tags to metrics (#50, @ChrisBr)

### Breaking changes

- Support for Ruby <= 2.2.x has been removed
- Support for Rails <= 4.1.x has been removed
- Removed previously deprecated methods:
  - `InfluxDB::Rails::Configuration#reraise_global_exceptions`
  - `InfluxDB::Rails::Configuration#database_name`
  - `InfluxDB::Rails::Configuration#application_id`

## v0.4.3, released 2017-12-12

- Added `time_precision` config option (#42, @kkentzo)

## v0.4.2, released 2017-11-28

- Added `open_timeout`, `read_timeout`, and `max_delay` config options
  (#41, @emaxi)
- Deprecate unused method (`#reraise_global_exceptions` in
  `InfluxDB::Rails::Configuration`, #37, @vassilevsky)

## v0.4.1, released 2017-10-23

- Bump `influx` version dependency (#40, @rockclimber73)

## v0.4.0, released 2017-08-19

- Drop support for Rails 3, Ruby < 2.2
- Sync version with `influxdb` gem

## v0.1.12, released 2017-06-06

- Added Rails 5.1 compatibility (#31, @djgould).
- Added `retry` config option (#17, @scambra and #18, @bcantin).

## v0.1.11, released 2016-11-24

- Bumped `influxdb` Rubygem dependency (#28, #32, @agx).

**Note:** The real changelog starts here. Previous entries are reconstructed
from the commit history by correlating release version with Git tags, which
may or may not reflect what was really released.

## v0.1.10, released 2014-10-08

- Lazy loading of `InfluxDB::Client` (#15, @chingo13).
- Various test fixes.

## v0.1.9, released 2014-06-18

- v0.1.8 was yanked
- Initializer now allows multiple hosts.

## v0.1.7, released 2014-04-09

- Added logger.

## v0.1.6, released 2014-04-08

- No changes (?)

## v0.1.5, released 2014-04-02

- No changes (?)

## v0.1.4, released 2014-03-26

- Added docs
- Made `async` option default to `true`.

## v0.1.3, released 2014-02-11

- Set series name defaults.
- Fixed a configuration bug.

## v0.1.2, released 2014-02-11

- Graceful handling of authentication errors.
- Fixes in documentation.

## v0.1.1, released 2014-02-06

- Refactoring of `ActiveSupport::Notification` handling.
- Added more initializer options.

## v0.1.0, released 2014-02-06

- Larger refactoring.
