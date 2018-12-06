module InfluxDB
  module Rails
    module Middleware
      # AsyncSubscriber runs composed subscriber instances in the background
      class AsyncSubscriber
        def initialize(subscriber)
          @subscriber = subscriber
        end

        def call(name, started, finished, unique_id, payload)
          payload[:location] = location
          execute_in_background do
            subscriber.call(name, started, finished, unique_id, payload)
          end
        end

        private

        attr_reader :subscriber

        def location
          [
            Thread.current[:_influxdb_rails_controller],
            Thread.current[:_influxdb_rails_action],
          ].reject(&:blank?).join("#")
        end

        def execute_in_background
          Thread.new do
            yield
          end
        end
      end
    end
  end
end
