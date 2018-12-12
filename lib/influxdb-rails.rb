require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "influxdb/rails/middleware/render_subscriber"
require "influxdb/rails/middleware/request_subscriber"
require "influxdb/rails/middleware/sql_subscriber"
require "influxdb/rails/sql/query"
require "influxdb/rails/version"
require "influxdb/rails/logger"
require "influxdb/rails/exception_presenter"
require "influxdb/rails/configuration"
require "influxdb/rails/backtrace"
require "influxdb/rails/context"
require "influxdb/rails/rack"

require "influxdb/rails/railtie" if defined?(Rails::Railtie)

module InfluxDB
  # InfluxDB::Rails contains the glue code needed to integrate with
  # InfluxDB and Rails. This is a singleton class.
  module Rails
    class << self
      include InfluxDB::Rails::Logger

      attr_writer :configuration
      attr_writer :client

      def configure(_silent = false)
        yield(configuration)

        # if we change configuration, reload the client
        self.client = nil

        InfluxDB::Logging.logger = configuration.logger unless configuration.logger.nil?
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      def client
        @client ||= InfluxDB::Client.new \
          database:       configuration.influxdb_database,
          username:       configuration.influxdb_username,
          password:       configuration.influxdb_password,
          hosts:          configuration.influxdb_hosts,
          port:           configuration.influxdb_port,
          async:          configuration.async,
          use_ssl:        configuration.use_ssl,
          retry:          configuration.retry,
          open_timeout:   configuration.open_timeout,
          read_timeout:   configuration.read_timeout,
          max_delay:      configuration.max_delay,
          time_precision: configuration.time_precision
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def configuration
        @configuration ||= InfluxDB::Rails::Configuration.new
      end

      def current
        @current ||= InfluxDB::Rails::Context.new
      end

      def report_exception_unless_ignorable(ex, env = {})
        report_exception(ex, env) unless ignorable_exception?(ex)
      end
      alias transmit_unless_ignorable report_exception_unless_ignorable

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      def report_exception(ex, env = {})
        timestamp = InfluxDB::Rails.current_timestamp
        env = influxdb_request_data if env.empty? && defined? influxdb_request_data
        exception_presenter = ExceptionPresenter.new(ex, env)
        log :info, "Exception: #{exception_presenter.to_json[0..512]}..."
        tags = configuration.tags_middleware.call(
          exception_presenter.context.merge(exception_presenter.dimensions)
        )

        client.write_point \
          configuration.series_name_for_exceptions,
          values:    exception_presenter.values.merge(ts: timestamp),
          tags:      tags,
          timestamp: timestamp
      rescue StandardError => ex
        log :info, "[InfluxDB::Rails] Something went terribly wrong." \
          " Exception failed to take off! #{ex.class}: #{ex.message}"
      end
      alias transmit report_exception

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def current_timestamp
        InfluxDB.now(configuration.time_precision)
      end

      def ignorable_exception?(ex)
        configuration.ignore_current_environment? || configuration.ignore_exception?(ex)
      end

      def rescue
        yield
      rescue StandardError => ex
        raise ex if configuration.ignore_current_environment?

        transmit_unless_ignorable(ex)
      end

      def rescue_and_reraise
        yield
      rescue StandardError => ex
        transmit_unless_ignorable(ex)
        raise ex
      end
    end
  end
end
