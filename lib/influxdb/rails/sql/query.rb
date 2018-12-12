require "influxdb/rails/sql/normalizer"

module InfluxDB
  module Rails
    module Sql
      class Query # :nodoc:
        attr_reader :query, :name

        TRACKED_SQL_COMMANDS = %w[SELECT INSERT UPDATE DELETE].freeze
        UNTRACKED_NAMES = %w[SCHEMA].freeze

        def initialize(payload)
          @query = payload[:sql].to_s.dup.upcase
          @name = payload[:name].to_s.dup
        end

        def operation
          query.split.first
        end

        def class_name
          name.split.first
        end

        def track?
          @track ||= query.start_with?(*TRACKED_SQL_COMMANDS) &&
                     !name.upcase.start_with?(*UNTRACKED_NAMES)
        end
      end
    end
  end
end
