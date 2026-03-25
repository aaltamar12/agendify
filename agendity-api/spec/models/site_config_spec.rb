require "rails_helper"

RSpec.describe SiteConfig, type: :model do
  describe "validations" do
    subject { build(:site_config) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe ".get" do
    it "returns the value for a given key" do
      create(:site_config, key: "nequi_phone", value: "3001234567")
      expect(described_class.get("nequi_phone")).to eq("3001234567")
    end

    it "returns nil when key does not exist" do
      expect(described_class.get("nonexistent")).to be_nil
    end
  end

  describe ".set" do
    it "creates a new config" do
      described_class.set("new_key", "new_value", description: "A new setting")
      config = described_class.find_by(key: "new_key")
      expect(config.value).to eq("new_value")
      expect(config.description).to eq("A new setting")
    end

    it "updates an existing config" do
      create(:site_config, key: "existing", value: "old")
      described_class.set("existing", "new")
      expect(described_class.get("existing")).to eq("new")
    end
  end
end
