module InfluxDB
  module Rails
    module Middleware
      module HijackRenderException # rubocop:disable Style/Documentation
        def render_exception(env, ex)
          controller = env["action_controller.instance"] || env.controller_instance
          request_data = controller.try(:influxdb_request_data) || {}
          unless InfluxDB::Rails.configuration.ignore_user_agent?(request_data[:user_agent])
            InfluxDB::Rails.report_exception_unless_ignorable(ex, request_data)
          end
          super
        end
      end
    end
  end
end
