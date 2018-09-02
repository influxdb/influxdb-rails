module InfluxDB
  module Rails
    module Instrumentation # rubocop:disable Style/Documentation
      def benchmark_for_instrumentationn # rubocop:disable Metrics/MethodLength
        start = Time.now
        yield

        c = InfluxDB::Rails.configuration
        return if c.ignore_current_environment?

        InfluxDB::Rails.client.write_point \
          c.series_name_for_instrumentation,
          values: {
            value: ((Time.now - start) * 1000).ceil,
          },
          tags: configuration.tags_middleware.call(
            method: "#{controller_name}##{action_name}",
            server: Socket.gethostname,
          )
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # rubocop:disable Style/Documentation
        def instrument(methods = [])
          methods = [methods] unless methods.is_a?(Array)
          around_filter :benchmark_for_instrumentation, only: methods
        end
      end
    end
  end
end
