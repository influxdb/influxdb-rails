require "spec_helper"

RSpec.describe WidgetsController, type: :controller do
  describe "#new" do
    it "should raise an exception" do
      expect { get :new }.to raise_error(ZeroDivisionError)
    end
  end

  describe "#index" do
    it "should not raise an exception" do
      expect { get :index }.to_not raise_error
    end
  end
end
