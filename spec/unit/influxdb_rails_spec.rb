require 'spec_helper'

RSpec.describe InfluxDB::Rails do
  before do
    InfluxDB::Rails.configure { |config| config.ignored_environments = [] }
  end

  describe '.convert_timestamp' do
    let(:sometime) { Time.parse('2017-12-11 16:20:29.111222333 UTC') }
    let(:configuration) { double("Configuration") }
    before { allow(InfluxDB::Rails).to receive(:configuration).and_return configuration }

    it "should return the timestamp in nanoseconds when precision is 'ns'" do
      allow(configuration).to receive(:time_precision).and_return('ns')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(1513009229111222272)
    end
    it "should return the timestamp in nanoseconds when precision is nil" do
      allow(configuration).to receive(:time_precision)
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(1513009229111222272)
    end
    it "should return the timestamp in microseconds when precision is u" do
      allow(configuration).to receive(:time_precision).and_return('u')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(1513009229111222)
    end
    it "should return the timestamp in milliseconds when precision is ms" do
      allow(configuration).to receive(:time_precision).and_return('ms')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(1513009229111)
    end
    it "should return the timestamp in seconds when precision is s" do
      allow(configuration).to receive(:time_precision).and_return('s')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(1513009229)
    end
    it "should return the timestamp in minutes when precision is m" do
      allow(configuration).to receive(:time_precision).and_return('m')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(25216820)
    end
    it "should return the timestamp in hours when precision is h" do
      allow(configuration).to receive(:time_precision).and_return('h')
      expect(InfluxDB::Rails.convert_timestamp(sometime)).to eq(420280)
    end
    it "should raise an excpetion when precision is unrecognized" do
      allow(configuration).to receive(:time_precision).and_return('whatever')
      expect{InfluxDB::Rails.convert_timestamp(sometime)}.
        to raise_exception /invalid time precision.*whatever/i
    end
  end

  describe '.current_timestamp' do
    it "should return the current timestamp in the configured precision" do
      now = Time.parse('2017-12-11 16:20:29.111222333 UTC')
      allow(Time).to receive(:now).and_return(now)
      InfluxDB::Rails.configure {|config| config.time_precision = 'ms'}
      expect(InfluxDB::Rails.current_timestamp).to eq(1513009229111)
    end
  end

  describe ".ignorable_exception?" do
    it "should be true for exception types specified in the configuration" do
      class DummyException < Exception; end
      exception = DummyException.new

      InfluxDB::Rails.configure do |config|
        config.ignored_exceptions << 'DummyException'
      end

      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_truthy
    end

    it "should be true for exception types specified in the configuration" do
      exception = ActionController::RoutingError.new("foo")
      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_truthy
    end

    it "should be false for valid exceptions" do
      exception = ZeroDivisionError.new
      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_falsey
    end
  end

  describe 'rescue' do
    it "should transmit an exception when passed" do
      InfluxDB::Rails.configure do |config|
        config.ignored_environments = []
        config.instrumentation_enabled = false
      end

      expect(InfluxDB::Rails.client).to receive(:write_point)

      InfluxDB::Rails.rescue do
        raise ArgumentError.new('wrong')
      end
    end

    it "should also raise the exception when in an ignored environment" do
      InfluxDB::Rails.configure { |config| config.ignored_environments = %w{development test} }

      expect {
        InfluxDB::Rails.rescue do
          raise ArgumentError.new('wrong')
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe "rescue_and_reraise" do
    it "should transmit an exception when passed" do
      InfluxDB::Rails.configure { |config| config.ignored_environments = [] }

      expect(InfluxDB::Rails.client).to receive(:write_point)

      expect {
        InfluxDB::Rails.rescue_and_reraise { raise ArgumentError.new('wrong') }
      }.to raise_error(ArgumentError)
    end
  end
end
