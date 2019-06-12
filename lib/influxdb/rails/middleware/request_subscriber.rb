require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RequestSubscriber < Subscriber # :nodoc:
        def call(_name, start, finish, _id, payload) # rubocop:disable Metrics/MethodLength
          return unless enabled?

          started = InfluxDB.convert_timestamp(start.utc, configuration.time_precision)
          tags = tags(payload)
          begin
            series(payload, start, finish).each do |series_name, value|
              InfluxDB::Rails.client.write_point \
                series_name,
                values:    values(value, started),
                tags:      tags,
                timestamp: InfluxDB::Rails.current_timestamp
            end
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          ensure
            InfluxDB::Rails.current.reset
          end
        end

        private

        def values(duration, started)
          addititional_values = InfluxDB::Rails.current.values
          { value: duration, started: started }.merge(addititional_values).reject do |_, value|
            value.nil? || value == ""
          end
        end

        def series(payload, start, finish)
          {
            configuration.series_name_for_controller_runtimes => ((finish - start) * 1000).ceil,
            configuration.series_name_for_view_runtimes       => (payload[:view_runtime] || 0).ceil,
            configuration.series_name_for_db_runtimes         => (payload[:db_runtime] || 0).ceil,
          }
        end

        def tags(payload)
          tags = {
            method:      "#{payload[:controller]}##{payload[:action]}",
            status:      payload[:status],
            format:      payload[:format],
            http_method: payload[:method],
            server:      Socket.gethostname,
            app_name:    configuration.application_name,
          }
          super(tags)
        end
      end
    end
  end
end
