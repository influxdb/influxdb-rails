require "influxdb"
require "rails"

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "influxdb.insert_rack_middleware" do |app|
        app.config.middleware.insert 0, InfluxDB::Rails::Rack
      end

      config.after_initialize do # rubocop:disable Metrics/BlockLength
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
          cache = lambda do |_, _, _, _, payload|
            current = InfluxDB::Rails.current
            current.controller = payload[:controller]
            current.action     = payload[:action]
          end
          ActiveSupport::Notifications.subscribe "start_processing.action_controller", &cache

          c = InfluxDB::Rails.configuration
          requests = Middleware::RequestSubscriber.new(c)
          ActiveSupport::Notifications.subscribe "process_action.action_controller", requests

          templates = Middleware::RenderSubscriber.new(c, c.series_name_for_render_template)
          ActiveSupport::Notifications.subscribe "render_template.action_view", templates

          partials = Middleware::RenderSubscriber.new(c, c.series_name_for_render_partial)
          ActiveSupport::Notifications.subscribe "render_partial.action_view", partials

          collections = Middleware::RenderSubscriber.new(c, c.series_name_for_render_collection)
          ActiveSupport::Notifications.subscribe "render_collection.action_view", collections

          sql = Middleware::SqlSubscriber.new(c, c.series_name_for_sql)
          ActiveSupport::Notifications.subscribe "sql.active_record", sql
        end
      end
    end
  end
end
