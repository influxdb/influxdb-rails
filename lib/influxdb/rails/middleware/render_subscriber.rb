require "influxdb/rails/middleware/simple_subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber < SimpleSubscriber # :nodoc:
        private

        def values(started, finished, payload)
          super(started, finished, payload).merge(
            count:      payload[:count],
            cache_hits: payload[:cache_hits]
          ).reject { |_, value| value.nil? }
        end

        def tags(payload)
          tags = {
            location: location,
            filename: payload[:identifier],
          }
          super(tags)
        end
      end
    end
  end
end
