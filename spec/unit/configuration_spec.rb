require 'spec_helper'

describe InfluxDB::Rails::Configuration do
  before do
    @configuration = InfluxDB::Rails::Configuration.new
  end

  describe "#ignore_user_agent?" do
    it "should be true for user agents that have been set as ignorable" do
      @configuration.ignored_user_agents = %w{Googlebot}
      expect(@configuration.ignore_user_agent?("Googlebot/2.1")).to be_truthy
    end

    it "should be false for user agents that have not been set as ignorable" do
      @configuration.ignored_user_agents = %w{Googlebot}
      expect(@configuration.ignore_user_agent?("Mozilla/5.0")).to be_falsey
    end

    it "should be false if the ignored user agents list is empty" do
      @configuration.ignored_user_agents = []
      expect(@configuration.ignore_user_agent?("Googlebot/2.1")).to be_falsey
    end

    it "should be false if the ignored user agents list is inadvertently set to nil" do
      @configuration.ignored_user_agents = nil
      expect(@configuration.ignore_user_agent?("Googlebot/2.1")).to be_falsey
    end
  end

  describe "#retry" do
    it "defaults to nil" do
      InfluxDB::Rails.configure do |config|
      end
      InfluxDB::Rails.configuration.retry.should be_nil
    end

    it "can be updated" do
      InfluxDB::Rails.configure do |config|
        config.retry = 5
      end
      InfluxDB::Rails.configuration.retry.should eql( 5 )
    end
  end

end
