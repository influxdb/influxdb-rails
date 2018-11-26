require "spec_helper"

RSpec.describe InfluxDB::Rails::ExceptionPresenter do
  before do
    begin
      1 / 0
    rescue ZeroDivisionError => e
      @exception = e
    end
  end

  describe ".new" do
    it "should create a new ExceptionPresenter" do
      exception_presenter = InfluxDB::Rails::ExceptionPresenter.new(@exception)
      expect(exception_presenter).to be_a(InfluxDB::Rails::ExceptionPresenter)
    end

    it "should accept an exception as a parameter" do
      exception_presenter = InfluxDB::Rails::ExceptionPresenter.new(@exception)
      expect(exception_presenter).not_to be_nil
    end
  end
end
