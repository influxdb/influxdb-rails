require "spec_helper"
require "shared_examples/tags"

RSpec.describe InfluxDB::Rails::Middleware::RenderSubscriber do
  let(:config) { InfluxDB::Rails::Configuration.new }
  let(:logger) { double(:logger) }

  before do
    allow(config).to receive(:application_name).and_return("my-rails-app")
    allow(config).to receive(:ignored_environments).and_return([])
    allow(config).to receive(:time_precision).and_return("ms")
  end

  describe ".call" do
    let(:start)   { Time.at(1_517_567_368) }
    let(:finish)  { Time.at(1_517_567_370) }
    let(:series_name) { "series_name" }
    let(:payload) { { identifier: "index.html", count: 43, cache_hits: 42 } }
    let(:data) do
      {
        values:    {
          value:      2000,
          count:      43,
          cache_hits: 42
        },
        tags:      {
          filename: "index.html",
          location: "Foo#bar",
        },
        timestamp: 1_517_567_370_000
      }
    end

    subject { described_class.new(config, series_name) }

    before do
      InfluxDB::Rails.current.controller = "Foo"
      InfluxDB::Rails.current.action = "bar"
    end

    after do
      InfluxDB::Rails.current.reset
    end

    context "successfully" do
      it "writes to InfluxDB" do
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          series_name, data
        )
        subject.call("name", start, finish, "id", payload)
      end

      it_behaves_like "with additional tags", ["series_name"]

      context "with an empty value" do
        before do
          payload[:count] = nil
          data[:values].delete(:count)
        end

        it "does not write empty value" do
          expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
            series_name, data
          )
          subject.call("name", start, finish, "id", payload)
        end
      end

      context "disabled" do
        subject { described_class.new(config, nil) }

        it "does not write a data point" do
          expect_any_instance_of(InfluxDB::Client).not_to receive(:write_point)
          subject.call("name", start, finish, "id", payload)
        end
      end
    end

    context "unsuccessfully" do
      before do
        allow(config).to receive(:logger).and_return(logger)
        InfluxDB::Rails.configuration = config
      end

      it "does log exceptions" do
        allow_any_instance_of(InfluxDB::Client).to receive(:write_point).and_raise("boom")
        expect(logger).to receive(:error).with(/boom/)
        subject.call("name", start, finish, "id", payload)
      end
    end
  end
end
