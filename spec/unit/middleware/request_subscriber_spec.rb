require "spec_helper"
require "shared_examples/tags"

RSpec.describe InfluxDB::Rails::Middleware::RequestSubscriber do
  let(:config) { InfluxDB::Rails::Configuration.new }

  before do
    allow(config).to receive(:time_precision).and_return("ms")
  end

  subject { described_class.new(config) }

  describe "#call" do
    let(:start)   { Time.at(1_517_567_368) }
    let(:finish)  { Time.at(1_517_567_370) }
    let(:payload) { { view_runtime: 2, db_runtime: 2, controller: "MyController", action: "show", method: "GET", format: "*/*", status: 200 } }
    let(:data)    do
      {
        values:    {
          value: 2
        },
        tags:      {
          method:      "MyController#show",
          status:      200,
          format:      "*/*",
          http_method: "GET",
          server:      Socket.gethostname,
          app_name:    "my-rails-app",
        },
        timestamp: 1_517_567_370_000
      }
    end

    context "application_name is set" do
      before do
        allow(config).to receive(:application_name).and_return("my-rails-app")
      end

      it "sends metrics with taggings and timestamps" do
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          "rails.controller", data.merge(values: { value: 2000 })
        )
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with("rails.view", data)
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with("rails.db", data)

        subject.call("unused", start, finish, "unused", payload)
      end

      it_behaves_like "with additional tags", ["rails.controller", "rails.view", "rails.db"]
    end

    context "application_name is nil" do
      before do
        allow(config).to receive(:application_name).and_return(nil)
      end

      it "does not add the app_name tag to metrics" do
        tags = {
          method:      "MyController#show",
          status:      200,
          format:      "*/*",
          http_method: "GET",
          server:      Socket.gethostname,
        }

        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          "rails.controller", data.merge(values: { value: 2000 }, tags: tags)
        )
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with("rails.view", data.merge(tags: tags))
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with("rails.db", data.merge(tags: tags))

        subject.call("unused", start, finish, "unused", payload)
      end
    end

    context "not successfull" do
      let(:logger) { double(:logger) }

      before do
        allow(config).to receive(:logger).and_return(logger)
        InfluxDB::Rails.configuration = config
      end

      it "does log an error" do
        allow_any_instance_of(InfluxDB::Client).to receive(:write_point).and_raise("boom")
        expect(logger).to receive(:error).with(/boom/)
        subject.call("name", start, finish, "id", payload)
      end
    end
  end
end
