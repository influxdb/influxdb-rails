require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "thread"

require "influxdb/rails/version"
require "influxdb/rails/logger"
require "influxdb/rails/exception_presenter"
require "influxdb/rails/configuration"
require "influxdb/rails/backtrace"
require "influxdb/rails/rack"

require "influxdb/rails/railtie" if defined?(Rails::Railtie)

module InfluxDB
  module Rails
    class << self
      include InfluxDB::Rails::Logger

      attr_writer :configuration
      attr_writer :client

      def configure(silent = false)
        yield(configuration)

        # if we change configuration, reload the client
        self.client = nil

        InfluxDB::Logging.logger = configuration.logger unless configuration.logger.nil?
      end

      def client
        @client ||= InfluxDB::Client.new configuration.influxdb_database,
          :username => configuration.influxdb_username,
          :password => configuration.influxdb_password,
          :hosts => configuration.influxdb_hosts,
          :port => configuration.influxdb_port,
          :async => configuration.async,
          :use_ssl => configuration.use_ssl,
          :retry => configuration.retry
      end

      def configuration
        @configuration ||= InfluxDB::Rails::Configuration.new
      end

      def report_exception_unless_ignorable(e, env = {})
        report_exception(e, env) unless ignorable_exception?(e)
      end
      alias_method :transmit_unless_ignorable, :report_exception_unless_ignorable

      def report_exception(e, env = {})
        begin
          env = influxdb_request_data if env.empty? && defined? influxdb_request_data
          exception_presenter = ExceptionPresenter.new(e, env)
          log :info, "Exception: #{exception_presenter.to_json[0..512]}..."

          ex_data = exception_presenter.context.merge(exception_presenter.dimensions)
          timestamp = ex_data.delete(:time)

          client.write_point "rails.exceptions", {
            values: {
              ts: timestamp,
            },
            tags: ex_data,
            timestamp: timestamp,
          }
        rescue => e
          log :info, "[InfluxDB::Rails] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
        end
      end
      alias_method :transmit, :report_exception

      def handle_action_controller_metrics(name, start, finish, id, payload)
        timestamp = finish.utc.to_i
        controller_runtime = ((finish - start)*1000).ceil
        view_runtime = (payload[:view_runtime] || 0).ceil
        db_runtime = (payload[:db_runtime] || 0).ceil
        method = "#{payload[:controller]}##{payload[:action]}"
        hostname = Socket.gethostname

        begin
          client.write_point configuration.series_name_for_controller_runtimes, {
            values: {
              value: controller_runtime,
            },
            tags: {
              method: method,
              server: hostname,
            },
          }

          client.write_point configuration.series_name_for_view_runtimes, {
            values: {
              value: view_runtime,
            },
            tags: {
              method: method,
              server: hostname,
            },
          }

          client.write_point configuration.series_name_for_db_runtimes, {
            values: {
              value: db_runtime,
            },
            tags: {
              method: method,
              server: hostname,
            },
          }
        rescue => e
          log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
        end
      end

      def current_timestamp
        Time.now.utc.to_i
      end

      def ignorable_exception?(e)
        configuration.ignore_current_environment? ||
        !!configuration.ignored_exception_messages.find{ |msg| /.*#{msg}.*/ =~ e.message  } ||
        configuration.ignored_exceptions.include?(e.class.to_s)
      end

      def rescue(&block)
        block.call
      rescue StandardError => e
        if configuration.ignore_current_environment?
          raise(e)
        else
          transmit_unless_ignorable(e)
        end
      end

      def rescue_and_reraise(&block)
        block.call
      rescue StandardError => e
        transmit_unless_ignorable(e)
        raise(e)
      end
    end
  end
end
