module InfluxDB
  module Rails
    module Middleware
      module HijackRescueActionEverywhere # rubocop:disable Style/Documentation
        def self.included(base)
          base.send(:alias_method_chain, :rescue_action_in_public, :influxdb)
          base.send(:alias_method_chain, :rescue_action_locally, :influxdb)
        end

        private

        def rescue_action_in_public_with_influxdb(ex)
          handle_exception(ex)
          rescue_action_in_public_without_influxdb(ex)
        end

        def rescue_action_locally_with_influxdb(ex)
          handle_exception(ex)
          rescue_action_locally_without_influxdb(ex)
        end

        def handle_exception(ex)
          request_data = influxdb_request_data || {}
          return if InfluxDB::Rails.configuration.ignore_user_agent?(request_data[:user_agent])

          InfluxDB::Rails.report_exception_unless_ignorable(ex, request_data)
        end
      end
    end
  end
end
