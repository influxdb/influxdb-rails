require "spec_helper"

RSpec.describe InfluxDB::Rails::Backtrace do
  before do
    @raw_backtrace = [
      "/var/www/current/app/models/foo.rb:10:in `bar'",
      "/var/www/current/app/models/foo.rb:19:in `baz'",
      "/var/www/current/app/models/foo.rb:32:in `<main>'"
    ]

    @backtrace = InfluxDB::Rails::Backtrace.new(@raw_backtrace)
  end

  it "should accept an exception into the initializer" do
    expect(@backtrace.lines).not_to be_empty
    expect(@backtrace.lines.count).to eq(3)
  end

  it "should correctly parse lines into their elements" do
    line = @backtrace.lines.first

    expect(line.file).to eq("/var/www/current/app/models/foo.rb")
    expect(line.number).to eq("10")
    expect(line.method).to eq("bar")
  end

  describe "#to_a" do
    it "should return an array of lines" do
      expect(@backtrace.to_a.is_a?(Array)).to be_truthy
    end
  end

  context "nil backtrace" do
    before do
      @raw_backtrace = nil
      @backtrace = InfluxDB::Rails::Backtrace.new(@raw_backtrace)
    end

    it "should accept an exception into the initializer" do
      expect(@backtrace.lines).to be_empty
      expect(@backtrace.lines.count).to eq(0)
    end

    describe "#to_a" do
      it "should return an array of lines" do
        expect(@backtrace.to_a.is_a?(Array)).to be_truthy
      end
    end
  end

  describe "backtrace filters" do
    before do
      InfluxDB::Rails.configure do |config|
        config.application_root = "/var/www/current"
      end
    end

    it "should apply a single default backtrace filter correctly" do
      filtered_backtrace = InfluxDB::Rails::Backtrace.new(@raw_backtrace)

      line = filtered_backtrace.lines.first
      expect(line.file).to eq("[APP_ROOT]/app/models/foo.rb")
    end

    it "should all default backtrace filters correctly" do
      extended_backtrace = @raw_backtrace.dup
      extended_backtrace << "#{Gem.path.first}/lib/foo_gem.rb:1:in `blah'"

      filtered_backtrace = InfluxDB::Rails::Backtrace.new(extended_backtrace)
      expect(filtered_backtrace.lines.first.file).to eq("[APP_ROOT]/app/models/foo.rb")
      expect(filtered_backtrace.lines.last.file).to eq("[GEM_ROOT]/lib/foo_gem.rb")
    end

    it "should allow the addition of custom backtrace filters" do
      InfluxDB::Rails.configure do |config|
        config.backtrace_filters << ->(line) { line.gsub(/foo/, "F00") }
      end

      filtered_backtrace = InfluxDB::Rails::Backtrace.new(@raw_backtrace)

      line = filtered_backtrace.lines.first
      expect(line.file).to eq("[APP_ROOT]/app/models/F00.rb")
    end
  end
end
