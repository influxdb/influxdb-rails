require "spec_helper"

RSpec.describe InfluxDB::Rails::Sql::Normalizer do
  describe "#perform" do
    it { expect(described_class.new("SELECT * FROM posts WHERE id = 1").perform).to eq("SELECT * FROM posts WHERE id = xxx") }
    it { expect(described_class.new("SELECT * FROM posts WHERE id = 1".freeze).perform).to eq("SELECT * FROM posts WHERE id = xxx") }
    it { expect(described_class.new("SELECT * FROM posts LIMIT 10").perform).to eq("SELECT * FROM posts LIMIT xxx") }
    it { expect(described_class.new("SELECT * FROM posts OFFSET 10").perform).to eq("SELECT * FROM posts OFFSET xxx") }
    it { expect(described_class.new("SELECT * FROM posts WHERE name LIKE '%foobar%'").perform).to eq("SELECT * FROM posts WHERE name LIKE xxx") }
    it { expect(described_class.new("SELECT * FROM posts WHERE id IN (1,2,3)").perform).to eq("SELECT * FROM posts WHERE id IN (xxx)") }
    it { expect(described_class.new("SELECT * FROM products WHERE price BETWEEN 10 AND 20").perform).to eq("SELECT * FROM products WHERE price BETWEEN xxx AND xxx") }
    it { expect(described_class.new("INSERT INTO products (title, price) VALUES ('Computer', 100)").perform).to eq("INSERT INTO products (title, price) VALUES (xxx)") }
    it { expect(described_class.new("   SELECT * FROM   POSTS    ").perform).to eq("SELECT * FROM POSTS") }
  end
end
