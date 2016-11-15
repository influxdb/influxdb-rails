module InfluxDB
  module Rails
    module Middleware
      module HijackRenderException
        def render_exception(env, e)
          controller = env["action_controller.instance"]
          request_data = controller.try(:influxdb_request_data) || {}
          unless InfluxDB::Rails.configuration.ignore_user_agent?(request_data[:user_agent])
            InfluxDB::Rails.report_exception_unless_ignorable(e, request_data)
          end
          super
        end
      end

      module OldHijackRenderException
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :influxdb)
        end

        def render_exception_with_influxdb(env, e)
          controller = env["action_controller.instance"]
          request_data = controller.try(:influxdb_request_data) || {}
          unless InfluxDB::Rails.configuration.ignore_user_agent?(request_data[:user_agent])
            InfluxDB::Rails.report_exception_unless_ignorable(e, request_data)
          end
          render_exception_without_influxdb(env, e)
        end
      end
    end
  end
end
