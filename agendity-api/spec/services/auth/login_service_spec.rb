require "rails_helper"

RSpec.describe Auth::LoginService do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "#call" do
    context "with valid credentials" do
      it "returns success with token and user" do
        result = described_class.call(email: "test@example.com", password: "password123")
        expect(result).to be_success
        expect(result.data[:token]).to be_present
        expect(result.data[:refresh_token]).to be_present
        expect(result.data[:user][:email]).to eq("test@example.com")
      end

      it "creates a refresh token" do
        expect {
          described_class.call(email: "test@example.com", password: "password123")
        }.to change(RefreshToken, :count).by(1)
      end
    end

    context "with invalid email" do
      it "returns failure" do
        result = described_class.call(email: "wrong@example.com", password: "password123")
        expect(result).to be_failure
        expect(result.error_code).to eq("INVALID_CREDENTIALS")
      end
    end

    context "with invalid password" do
      it "returns failure" do
        result = described_class.call(email: "test@example.com", password: "wrong")
        expect(result).to be_failure
        expect(result.error_code).to eq("INVALID_CREDENTIALS")
      end
    end
  end
end
