# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Passwords", type: :request do
  let(:user) { create(:user) }

  describe "POST /api/v1/auth/forgot_password" do
    it "returns success even with unknown email (prevents enumeration)" do
      post "/api/v1/auth/forgot_password", params: { email: "unknown@test.com" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["message"]).to be_present
    end

    it "returns success with valid email" do
      post "/api/v1/auth/forgot_password", params: { email: user.email }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/auth/reset_password" do
    it "returns 422 with invalid token" do
      post "/api/v1/auth/reset_password", params: {
        token: "invalid",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "resets password successfully with valid token" do
      raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
      user.update_columns(reset_password_token: hashed_token, reset_password_sent_at: Time.current)

      post "/api/v1/auth/reset_password", params: {
        token: raw_token,
        password: "newsecurepassword123",
        password_confirmation: "newsecurepassword123"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["message"]).to include("actualizada")
    end
  end
end
