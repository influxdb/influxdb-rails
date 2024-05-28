require "spec_helper"

RSpec.describe InfluxDB::Rails::Tags do
  let(:config) { InfluxDB::Rails::Configuration.new }

  describe ".to_h" do
    it "returns TrueClass" do
      subject = described_class.new(config: config, tags: { hans: true })
      expect(subject.to_h).to a_hash_including(hans: true)
    end

    it "returns FalseClass" do
      subject = described_class.new(config: config, tags: { hans: false })
      expect(subject.to_h).to a_hash_including(hans: false)
    end

    it "returns strings" do
      subject = described_class.new(config: config, tags: { hans: "franz" })
      expect(subject.to_h).to a_hash_including(hans: "franz")
    end

    it "returns strings containing blank" do
      subject = described_class.new(config: config, tags: { hans: "franz hans" })
      expect(subject.to_h).to a_hash_including(hans: "franz hans")
    end

    it "removes empty strings" do
      subject = described_class.new(config: config, tags: { hans: "", franz: "   " })
      expect(subject.to_h).not_to a_hash_including(:hans, :franz)
    end

    it "returns symbols" do
      subject = described_class.new(config: config, tags: { hans: :franz })
      expect(subject.to_h).to a_hash_including(hans: :franz)
    end

    it "removes nil" do
      subject = described_class.new(config: config, tags: { hans: nil })
      expect(subject.to_h).not_to a_hash_including(:hans)
    end

    it "leaves arrays alone" do
      subject = described_class.new(config: config, tags: { hans: [], franz: %w[a b] })
      expect(subject.to_h).to a_hash_including(hans: [], franz: %w[a b])
    end
  end
end
