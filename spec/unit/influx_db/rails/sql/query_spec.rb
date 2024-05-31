require "spec_helper"

RSpec.describe InfluxDB::Rails::Sql::Query do
  subject(:sql_query_with_payload) { described_class.new(payload) }

  let(:payload) do
    {
      sql:  "select * from users where user_id = 42;",
      name: "User Load",
    }
  end

  describe "#class_name" do
    it { expect(sql_query_with_payload.class_name).to eq("User") }
  end

  describe "#operation" do
    it { expect(sql_query_with_payload.operation).to eq("SELECT") }
  end

  describe "#track?" do
    it { expect(described_class.new(sql: "INSERT").track?).to be true }
    it { expect(described_class.new(sql: "UPDATE").track?).to be true }
    it { expect(described_class.new(sql: "SELECT").track?).to be true }
    it { expect(described_class.new(sql: "DELETE").track?).to be true }
    it { expect(described_class.new(sql: "SCHEMA").track?).to be false }
    it { expect(described_class.new(sql: "BEGIN").track?).to be false }
    it { expect(described_class.new(sql: "SELECT", name: "SCHEMA").track?).to be false }
  end
end
