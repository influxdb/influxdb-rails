require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "influxdb/rails/version"
require "influxdb/rails/logger"
require "influxdb/rails/exception_presenter"
require "influxdb/rails/configuration"
require "influxdb/rails/backtrace"
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

      def report_exception_unless_ignorable(e, env = {})
        report_exception(e, env) unless ignorable_exception?(e)
      end
      alias transmit_unless_ignorable report_exception_unless_ignorable

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      def report_exception(e, env = {})
        timestamp = InfluxDB::Rails.current_timestamp
        env = influxdb_request_data if env.empty? && defined? influxdb_request_data
        exception_presenter = ExceptionPresenter.new(e, env)
        log :info, "Exception: #{exception_presenter.to_json[0..512]}..."

        client.write_point \
          configuration.series_name_for_exceptions,
          values:    exception_presenter.values.merge(ts: timestamp),
          tags:      exception_presenter.context.merge(exception_presenter.dimensions),
          timestamp: timestamp
      rescue StandardError => e
        log :info, "[InfluxDB::Rails] Something went terribly wrong." \
          " Exception failed to take off! #{e.class}: #{e.message}"
      end
      alias transmit report_exception

      def handle_action_controller_metrics(_name, start, finish, _id, payload)
        tags = {
          method:        "#{payload[:controller]}##{payload[:action]}",
          status:        payload[:status],
          format:        payload[:format],
          http_method:   payload[:method],
          path:          payload[:path],
          server:        Socket.gethostname,
          app_name:      configuration.application_name,
        }.reject { |_, value| value.nil? }

        ts = convert_timestamp(finish.utc)

        begin
          {
            configuration.series_name_for_controller_runtimes => ((finish - start) * 1000).ceil,
            configuration.series_name_for_view_runtimes       => (payload[:view_runtime] || 0).ceil,
            configuration.series_name_for_db_runtimes         => (payload[:db_runtime] || 0).ceil,
          }.each do |series_name, value|
            client.write_point series_name, values: { value: value }, tags: tags, timestamp: ts
          end
        rescue StandardError => e
          log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
        end
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      TIMESTAMP_CONVERSIONS = {
        "ns"  => 1e9.to_r,
        nil   => 1e9.to_r,
        "u"   => 1e6.to_r,
        "ms"  => 1e3.to_r,
        "s"   => 1.to_r,
        "m"   => 1.to_r / 60,
        "h"   => 1.to_r / 60 / 60,
      }.freeze
      private_constant :TIMESTAMP_CONVERSIONS

      def convert_timestamp(ts)
        conv = TIMESTAMP_CONVERSIONS.fetch(configuration.time_precision) do
          raise "Invalid time precision: #{configuration.time_precision}"
        end

        (ts.to_r * conv).to_i
      end

      def current_timestamp
        convert_timestamp(Time.now.utc)
      end

      def ignorable_exception?(e)
        configuration.ignore_current_environment? || configuration.ignore_exception?(e)
      end

      def rescue
        yield
      rescue StandardError => e
        raise(e) if configuration.ignore_current_environment?
        transmit_unless_ignorable(e)
      end

      def rescue_and_reraise
        yield
      rescue StandardError => e
        transmit_unless_ignorable(e)
        raise(e)
      end
    end
  end
end
