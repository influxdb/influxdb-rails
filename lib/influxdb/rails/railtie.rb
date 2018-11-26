require "influxdb"
require "rails"

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "influxdb.insert_rack_middleware" do |app|
        app.config.middleware.insert 0, InfluxDB::Rails::Rack
      end

      config.after_initialize do
        InfluxDB::Rails.configure(true, &:load_rails_defaults)

        ActiveSupport.on_load(:action_controller) do
          require "influxdb/rails/air_traffic_controller"
          include InfluxDB::Rails::AirTrafficController
          require "influxdb/rails/instrumentation"
          include InfluxDB::Rails::Instrumentation
        end

        require "influxdb/rails/middleware/hijack_render_exception"
        ::ActionDispatch::DebugExceptions.prepend InfluxDB::Rails::Middleware::HijackRenderException

        if defined?(ActiveSupport::Notifications)
          listen = lambda do |name, start, finish, id, payload|
            c = InfluxDB::Rails.configuration

            if c.instrumentation_enabled? && !c.ignore_current_environment?
              begin
                InfluxDB::Rails.handle_action_controller_metrics(name, start, finish, id, payload)
              rescue StandardError => e
                c.logger.error "[InfluxDB::Rails] Failed writing points to InfluxDB: #{e.message}"
              end
            end
          end

          ActiveSupport::Notifications.subscribe "process_action.action_controller", &listen
        end
      end
    end
  end
end
