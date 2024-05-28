require "active_support/concern"

module InfluxDB
  module Rails
    module Configurable
      extend ActiveSupport::Concern

      class_methods do
        def defaults
          @defaults ||= {}
        end

        def set_defaults(**values)
          defaults.merge! values
          attr_accessor(*defaults.keys)
        end
      end

      def load_defaults
        self.class.defaults.each do |key, value|
          val = value.dup rescue value
          public_send "#{key}=", val
        end
      end
    end
    private_constant :Configurable

    class ClientConfig
      include Configurable

      WRITE_TYPE = {
        true  => ::InfluxDB2::WriteType::BATCHING,
        false => ::InfluxDB2::WriteType::SYNCHRONOUS,
      }.freeze
      private_constant :WRITE_TYPE

      set_defaults(
        url:           "http://localhost:8086".freeze,
        token:         nil,
        org:           nil,
        bucket:        nil,
        use_ssl:       true,
        open_timeout:  5,
        write_timeout: 5,
        read_timeout:  60,
        precision:     ::InfluxDB2::WritePrecision::MILLISECOND,
        max_retries:   0,
        async:         true
      )

      def initialize
        load_defaults
      end

      def write_options
        InfluxDB2::WriteOptions.new(
          write_type:  WRITE_TYPE[async],
          max_retries: max_retries
        )
      end
    end
    private_constant :ClientConfig

    class Configuration
      include Configurable

      set_defaults(
        measurement_name:     "rails".freeze,
        ignored_hooks:        [].freeze,
        tags_middleware:      lambda { |tags|
                                tags.reject do |_key, value|
                                  value.nil? || (value.is_a?(String) && value.squish.empty?)
                                end
                              },
        rails_app_name:       nil,
        ignored_environments: %w[test cucumber selenium].freeze,
        environment:          ::Rails.env,
        debug:                false,
        logger:               ::Rails.logger
      )

      # config option set after_initialize
      attr_accessor(:environment, :application_name)

      # configuration passed to InfluxDB::Client
      attr_reader :client

      def initialize
        @client = ClientConfig.new
        load_defaults
      end

      def debug?
        @debug
      end

      def ignore_current_environment?
        ignored_environments.include?(environment)
      end
    end
  end
end
