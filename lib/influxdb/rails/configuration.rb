module InfluxDB
  module Rails
    class Configuration
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

      attr_accessor :series_name_for_controller_runtimes
      attr_accessor :series_name_for_view_runtimes
      attr_accessor :series_name_for_db_runtimes

      attr_accessor :application_id
      deprecate :application_id => "This method serve no purpose and will be removed in the release after 0.1.12"

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
      attr_accessor :reraise_global_exceptions


      DEFAULTS = {
        :influxdb_hosts     => ["localhost"],
        :influxdb_port      => 8086,
        :influxdb_username  => "root",
        :influxdb_password  => "root",
        :influxdb_database  => nil,
        :async              => true,
        :use_ssl            => false,
        :retry              => nil,
        :open_timeout       => 5,
        :read_timeout       => 300,
        :max_delay          => 30,

        :series_name_for_controller_runtimes  => "rails.controller",
        :series_name_for_view_runtimes        => "rails.view",
        :series_name_for_db_runtimes          => "rails.db",

        :ignored_exceptions => %w{ActiveRecord::RecordNotFound
                                  ActionController::RoutingError},
        :ignored_exception_messages => [],
        :ignored_reports => [],
        :ignored_environments => %w{test cucumber selenium},
        :ignored_user_agents => %w{GoogleBot},
        :environment_variable_filters => [
          /password/i,
          /key/i,
          /secret/i,
          /ps1/i,
          /rvm_.*_clr/i,
          /color/i
        ],
        :backtrace_filters => [
          lambda { |line| line.gsub(/^\.\//, "") },
          lambda { |line|
            return line if InfluxDB::Rails.configuration.application_root.to_s.empty?
            line.gsub(/#{InfluxDB::Rails.configuration.application_root}/, "[APP_ROOT]")
          },
          lambda { |line|
            if defined?(Gem) && !Gem.path.nil? && !Gem.path.empty?
              Gem.path.each { |path| line = line.gsub(/#{path}/, "[GEM_ROOT]") }
            end
            line
          }
        ]
      }

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

        @series_name_for_controller_runtimes  = DEFAULTS[:series_name_for_controller_runtimes]
        @series_name_for_view_runtimes        = DEFAULTS[:series_name_for_view_runtimes]
        @series_name_for_db_runtimes          = DEFAULTS[:series_name_for_db_runtimes]

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

      def debug?
        !!@debug
      end

      def instrumentation_enabled?
        !!@instrumentation_enabled
      end

      def reraise_global_exceptions?
        !!@reraise_global_exceptions
      end

      def ignore_user_agent?(incoming_user_agent)
        return false if self.ignored_user_agents.nil?
        self.ignored_user_agents.any? {|agent| incoming_user_agent =~ /#{agent}/}
      end

      def ignore_current_environment?
        self.ignored_environments.include?(self.environment)
      end

      def define_custom_exception_data(&block)
        @custom_exception_data_handler = block
      end

      def add_custom_exception_data(exception_presenter)
        @custom_exception_data_handler.call(exception_presenter) if @custom_exception_data_handler
      end

      def database_name
        @application_id.to_s + @environment.to_s
      end
      deprecate :database_name => "This method will be removed in the release after 0.1.12, you ought to use #influxdb_database"

      private
      def initialize_http_connection
        Net::HTTP.new(@app_host, "80")
      end
    end
  end
end
