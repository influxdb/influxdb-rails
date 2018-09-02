module InfluxDB
  module Rails
    # rubocop:disable Metrics/ClassLength

    class Configuration # rubocop:disable Style/Documentation
      attr_accessor :influxdb_hosts
      attr_accessor :influxdb_port
      attr_accessor :influxdb_username
      attr_accessor :influxdb_password
      attr_accessor :influxdb_database
      attr_accessor :async
      attr_accessor :use_ssl
      attr_accessor :retry
      attr_accessor :open_timeout
      attr_accessor :read_timeout
      attr_accessor :max_delay
      attr_accessor :time_precision

      attr_accessor :series_name_for_controller_runtimes
      attr_accessor :series_name_for_view_runtimes
      attr_accessor :series_name_for_db_runtimes
      attr_accessor :series_name_for_exceptions
      attr_accessor :series_name_for_instrumentation

      attr_accessor :tags_middleware

      attr_accessor :rails_app_name

      attr_accessor :application_name
      attr_accessor :application_root

      attr_accessor :logger
      attr_accessor :environment
      attr_accessor :framework
      attr_accessor :framework_version
      attr_accessor :language
      attr_accessor :language_version
      attr_accessor :ignored_exceptions
      attr_accessor :ignored_exception_messages
      attr_accessor :ignored_reports
      attr_accessor :ignored_environments
      attr_accessor :ignored_user_agents
      attr_accessor :backtrace_filters
      attr_accessor :aggregated_exception_classes
      attr_accessor :environment_variables
      attr_accessor :environment_variable_filters

      attr_accessor :instrumentation_enabled
      attr_accessor :debug

      DEFAULTS = {
        influxdb_hosts:     ["localhost"].freeze,
        influxdb_port:      8086,
        influxdb_username:  "root".freeze,
        influxdb_password:  "root".freeze,
        influxdb_database:  nil,
        async:              true,
        use_ssl:            false,
        retry:              nil,
        open_timeout:       5,
        read_timeout:       300,
        max_delay:          30,
        time_precision:     "s".freeze,

        series_name_for_controller_runtimes:  "rails.controller".freeze,
        series_name_for_view_runtimes:        "rails.view".freeze,
        series_name_for_db_runtimes:          "rails.db".freeze,
        series_name_for_exceptions:           "rails.exceptions".freeze,
        series_name_for_instrumentation:      "instrumentation".freeze,

        tags_middleware: ->(tags) { tags },
        rails_app_name: nil,

        ignored_exceptions: %w[
          ActiveRecord::RecordNotFound
          ActionController::RoutingError
        ].freeze,

        ignored_exception_messages:   [].freeze,
        ignored_reports:              [].freeze,
        ignored_environments:         %w[test cucumber selenium].freeze,
        ignored_user_agents:          %w[GoogleBot].freeze,
        environment_variable_filters: [
          /password/i,
          /key/i,
          /secret/i,
          /ps1/i,
          /rvm_.*_clr/i,
          /color/i,
        ].freeze,

        backtrace_filters: [
          ->(line) { line.gsub(%r{^\./}, "") },
          lambda { |line|
            return line if InfluxDB::Rails.configuration.application_root.to_s.empty?
            line.gsub(/#{InfluxDB::Rails.configuration.application_root}/, "[APP_ROOT]")
          },
          lambda { |line|
            if defined?(Gem) && !Gem.path.nil? && !Gem.path.empty?
              Gem.path.each { |path| line = line.gsub(/#{path}/, "[GEM_ROOT]") }
            end
            line
          },
        ].freeze,
      }.freeze

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      def initialize
        @influxdb_hosts     = DEFAULTS[:influxdb_hosts]
        @influxdb_port      = DEFAULTS[:influxdb_port]
        @influxdb_username  = DEFAULTS[:influxdb_username]
        @influxdb_password  = DEFAULTS[:influxdb_password]
        @influxdb_database  = DEFAULTS[:influxdb_database]
        @async              = DEFAULTS[:async]
        @use_ssl            = DEFAULTS[:use_ssl]
        @retry              = DEFAULTS[:retry]
        @open_timeout       = DEFAULTS[:open_timeout]
        @read_timeout       = DEFAULTS[:read_timeout]
        @max_delay          = DEFAULTS[:max_delay]
        @time_precision     = DEFAULTS[:time_precision]

        @series_name_for_controller_runtimes  = DEFAULTS[:series_name_for_controller_runtimes]
        @series_name_for_view_runtimes        = DEFAULTS[:series_name_for_view_runtimes]
        @series_name_for_db_runtimes          = DEFAULTS[:series_name_for_db_runtimes]
        @series_name_for_exceptions           = DEFAULTS[:series_name_for_exceptions]
        @series_name_for_instrumentation      = DEFAULTS[:series_name_for_instrumentation]

        @tags_middleware = DEFAULTS[:tags_middleware]
        @rails_app_name = DEFAULTS[:rails_app_name]

        @ignored_exceptions           = DEFAULTS[:ignored_exceptions].dup
        @ignored_exception_messages   = DEFAULTS[:ignored_exception_messages].dup
        @ignored_reports              = DEFAULTS[:ignored_reports].dup
        @ignored_environments         = DEFAULTS[:ignored_environments].dup
        @ignored_user_agents          = DEFAULTS[:ignored_user_agents].dup
        @backtrace_filters            = DEFAULTS[:backtrace_filters].dup
        @environment_variable_filters = DEFAULTS[:environment_variable_filters]
        @aggregated_exception_classes = []

        @debug                    = false
        @rescue_global_exceptions = false
        @instrumentation_enabled  = true
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def debug?
        !!@debug # rubocop:disable Style/DoubleNegation
      end

      def instrumentation_enabled?
        !!@instrumentation_enabled # rubocop:disable Style/DoubleNegation
      end

      def ignore_user_agent?(incoming_user_agent)
        return false if ignored_user_agents.nil?
        ignored_user_agents.any? { |agent| incoming_user_agent =~ /#{agent}/ }
      end

      def ignore_current_environment?
        ignored_environments.include?(environment)
      end

      def ignore_exception?(e)
        !ignored_exception_messages.find { |msg| /.*#{msg}.*/ =~ e.message }.nil? ||
          ignored_exceptions.include?(e.class.to_s)
      end

      def define_custom_exception_data(&block)
        @custom_exception_data_handler = block
      end

      def add_custom_exception_data(exception_presenter)
        @custom_exception_data_handler.call(exception_presenter) if @custom_exception_data_handler
      end

      def load_rails_defaults
        @logger           ||= ::Rails.logger
        @environment      ||= ::Rails.env
        @application_root ||= ::Rails.root
        @application_name ||= ::Rails.application.class.parent_name
        @framework          = "Rails"
        @framework_version  = ::Rails.version
      end

      private

      def initialize_http_connection
        Net::HTTP.new(@app_host, "80")
      end
    end

    # rubocop:enable Metrics/ClassLength
  end
end
