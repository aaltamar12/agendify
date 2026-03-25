require "rails_helper"

RSpec.describe Auth::RefreshTokenService do
  let(:user) { create(:user) }
  let!(:refresh_token) { create(:refresh_token, user: user, expires_at: 30.days.from_now) }

  describe "#call" do
    context "with valid refresh token" do
      it "returns new token pair" do
        result = described_class.call(refresh_token: refresh_token.token)
        expect(result).to be_success
        expect(result.data[:token]).to be_present
        expect(result.data[:refresh_token]).to be_present
      end

      it "destroys the old refresh token" do
        old_token = refresh_token.token
        described_class.call(refresh_token: old_token)
        expect(RefreshToken.find_by(token: old_token)).to be_nil
      end

      it "creates a new refresh token" do
        old_token = refresh_token.token
        result = described_class.call(refresh_token: old_token)
        expect(result.data[:refresh_token]).not_to eq(old_token)
      end
    end

    context "with expired refresh token" do
      before { refresh_token.update_column(:expires_at, 1.day.ago) }

      it "returns failure" do
        result = described_class.call(refresh_token: refresh_token.token)
        expect(result).to be_failure
        expect(result.error).to include("Invalid or expired")
      end
    end

    context "with nonexistent refresh token" do
      it "returns failure" do
        result = described_class.call(refresh_token: "nonexistent")
        expect(result).to be_failure
      end
    end
  end
end
