module InfluxDB
  module Rails
    module Logger # rubocop:disable Style/Documentation
      PREFIX = "[InfluxDB::Rails] ".freeze

      private

      def log(level, message)
        c = InfluxDB::Rails.configuration
        return if level != :error && !c.debug?

        c.logger&.send(level, PREFIX + message)
      end
    end
  end
end
