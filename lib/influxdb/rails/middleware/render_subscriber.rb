require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber < Subscriber # :nodoc:
        attr_reader :series_name

        def initialize(configuration, series_name)
          @series_name = series_name
          super(configuration)
        end

        # rubocop:disable Metrics/MethodLength

        def call(_name, started, finished, _unique_id, payload)
          return unless enabled?

          value = ((finished - started) * 1000).ceil
          ts = InfluxDB.convert_timestamp(finished.utc, configuration.time_precision)
          begin
            InfluxDB::Rails.client.write_point \
              series_name,
              values:    { value: value },
              tags:      tags(payload),
              timestamp: ts
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          end
        end

        # rubocop:enable Metrics/MethodLength

        private

        def enabled?
          super && series_name.present?
        end

        def tags(payload)
          {
            location:   payload[:location],
            filename:   payload[:identifier],
            count:      payload[:count],
            cache_hits: payload[:cache_hits],
          }.reject { |_, value| value.blank? }
        end
      end
    end
  end
end
