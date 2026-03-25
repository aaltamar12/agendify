require "rails_helper"

RSpec.describe Auth::LogoutService do
  let(:user) { create(:user) }
  let(:token) { Auth::TokenGenerator.encode(user) }

  before do
    create(:refresh_token, user: user)
  end

  describe "#call" do
    context "with valid token" do
      it "denylists the JWT" do
        expect {
          described_class.call(user: user, token: token)
        }.to change(JwtDenylist, :count).by(1)
      end

      it "destroys all refresh tokens" do
        expect {
          described_class.call(user: user, token: token)
        }.to change { user.refresh_tokens.count }.to(0)
      end

      it "returns success" do
        result = described_class.call(user: user, token: token)
        expect(result).to be_success
      end
    end

    context "with invalid token" do
      it "returns failure" do
        result = described_class.call(user: user, token: "invalid_token")
        expect(result).to be_failure
      end
    end
  end
end
