require "spec_helper"

RSpec.shared_examples_for "with additional tags" do |series_names|
  context "when tags_middleware is overwritten" do
    before do
      allow(config).to receive(:tags_middleware).and_return(tags_middleware)
    end

    let(:tags_middleware) { ->(tags) { tags.merge(static: "value") } }

    it "processes tags throught the middleware" do
      tags = data[:tags].merge(static: "value")

      series_names.each do |series_name|
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, include(tags: tags))
      end

      subject.call("unused", start, finish, "unused", payload)
    end
  end

  context "when tags are set in the current context" do
    let(:additional_tags) do
      { another: :value }
    end

    after do
      InfluxDB::Rails.current.reset
    end

    it "does include the tags" do
      InfluxDB::Rails.current.tags = additional_tags
      tags = data[:tags].merge(additional_tags)

      series_names.each do |series_name|
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, include(tags: tags))
      end

      subject.call("unused", start, finish, "unused", payload)
    end
  end
end
