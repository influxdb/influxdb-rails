module InfluxDB
  module Rails
    class Context # rubocop:disable Style/Documentation
      def controller
        Thread.current[:_influxdb_rails_controller]
      end

      def controller=(value)
        Thread.current[:_influxdb_rails_controller] = value
      end

      def action
        Thread.current[:_influxdb_rails_action]
      end

      def action=(value)
        Thread.current[:_influxdb_rails_action] = value
      end

      def location
        [
          controller,
          action,
        ].reject(&:blank?).join("#")
      end

      def reset
        Thread.current[:_influxdb_rails_controller] = nil
        Thread.current[:_influxdb_rails_action] = nil
        Thread.current[:_influxdb_rails_tags] = nil
      end

      def tags
        Thread.current[:_influxdb_rails_tags] || {}
      end

      def tags=(tags)
        Thread.current[:_influxdb_rails_tags] = tags
      end
    end
  end
end
