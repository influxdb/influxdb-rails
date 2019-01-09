require "influxdb/rails/middleware/simple_subscriber"
require "influxdb/rails/sql/query"

module InfluxDB
  module Rails
    module Middleware
      class SqlSubscriber < SimpleSubscriber # :nodoc:
        def call(_name, started, finished, _unique_id, payload)
          return unless InfluxDB::Rails::Sql::Query.new(payload).track?

          super
        end

        private

        def values(started, finished, payload)
          super.merge(sql: InfluxDB::Rails::Sql::Normalizer.new(payload[:sql]).perform)
        end

        def location
          result = super
          result.empty? ? :raw : result
        end

        def tags(payload)
          query = InfluxDB::Rails::Sql::Query.new(payload)
          tags = {
            location:   location,
            operation:  query.operation,
            class_name: query.class_name,
            name:       query.name,
          }
          super(tags)
        end
      end
    end
  end
end
