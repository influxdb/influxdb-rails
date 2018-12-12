require "spec_helper"

RSpec.describe InfluxDB::Rails::Context do
  subject { described_class.new }

  describe "#controller" do
    it "does set and get" do
      subject.controller = "Controller"
      expect(subject.controller).to eq("Controller")
    end
  end

  describe "#action" do
    it "does get and set" do
      subject.action = "action"
      expect(subject.action).to eq("action")
    end
  end

  describe "#location" do
    before do
      subject.controller = "Controller"
      subject.action = "action"
    end

    it { expect(subject.location).to eq("Controller#action") }
  end

  describe "#reset" do
    before do
      subject.controller = "Controller"
      subject.action = "action"
    end

    it "does reset the location" do
      subject.reset
      expect(subject.location).to be_empty
    end
  end
end
