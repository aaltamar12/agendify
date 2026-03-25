require "rails_helper"

RSpec.describe Auth::TokenGenerator do
  let(:user) { create(:user) }

  describe ".encode" do
    it "returns a JWT string" do
      token = described_class.encode(user)
      expect(token).to be_a(String)
      expect(token.split(".").length).to eq(3) # header.payload.signature
    end
  end

  describe ".decode" do
    it "decodes a valid token and returns payload" do
      token = described_class.encode(user)
      payload = described_class.decode(token)
      expect(payload[:sub]).to eq(user.id)
      expect(payload[:jti]).to be_present
      expect(payload[:exp]).to be_present
    end

    it "returns nil for an invalid token" do
      expect(described_class.decode("invalid.token.string")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode(user)
      travel_to 2.days.from_now do
        expect(described_class.decode(token)).to be_nil
      end
    end
  end
end
