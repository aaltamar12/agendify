# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Api::V1::AuthController, type: :request do
  describe "POST /api/v1/auth/login" do
    it "returns tokens on successful login" do
      result = OpenStruct.new(success?: true, data: { token: "jwt-token", refresh_token: "rt" })
      allow(Auth::LoginService).to receive(:call).and_return(result)

      post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["token"]).to eq("jwt-token")
    end

    it "returns unauthorized on failed login" do
      result = OpenStruct.new(success?: false, error: "Invalid credentials", details: nil)
      allow(Auth::LoginService).to receive(:call).and_return(result)

      post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Invalid credentials")
    end
  end

  describe "POST /api/v1/auth/register" do
    it "returns user data on successful registration" do
      result = OpenStruct.new(success?: true, data: { user: { id: 1 } })
      allow(Auth::RegisterService).to receive(:call).and_return(result)

      post "/api/v1/auth/register", params: {
        name: "Test", email: "test@example.com", password: "password123",
        password_confirmation: "password123", business_name: "My Biz", business_type: "barbershop",
        terms_accepted: true
      }

      expect(response).to have_http_status(:created)
    end

    it "returns errors on failed registration" do
      result = OpenStruct.new(success?: false, error: "Email taken", details: { email: ["has already been taken"] })
      allow(Auth::RegisterService).to receive(:call).and_return(result)

      post "/api/v1/auth/register", params: { name: "Test", email: "taken@example.com" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["details"]).to be_present
    end
  end

  describe "POST /api/v1/auth/refresh" do
    it "returns new tokens on successful refresh" do
      result = OpenStruct.new(success?: true, data: { token: "new-jwt" })
      allow(Auth::RefreshTokenService).to receive(:call).and_return(result)

      post "/api/v1/auth/refresh", params: { refresh_token: "valid-rt" }

      expect(response).to have_http_status(:ok)
    end

    it "returns unauthorized on invalid refresh token" do
      result = OpenStruct.new(success?: false, error: "Invalid refresh token", details: nil)
      allow(Auth::RefreshTokenService).to receive(:call).and_return(result)

      post "/api/v1/auth/refresh", params: { refresh_token: "expired-rt" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user) }
    let!(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    it "returns current user info" do
      get "/api/v1/auth/me", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_present
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:user) { create(:user) }
    let!(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    before do
      # Stub Warden JWT revocation middleware to avoid nil scope error
      allow_any_instance_of(Warden::JWTAuth::TokenRevoker).to receive(:call)
    end

    it "logs out successfully" do
      result = OpenStruct.new(success?: true)
      allow(Auth::LogoutService).to receive(:call).and_return(result)

      delete "/api/v1/auth/logout", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["message"]).to include("cerrada")
    end

    it "returns error on logout failure" do
      result = OpenStruct.new(success?: false, error: "Token not found")
      allow(Auth::LogoutService).to receive(:call).and_return(result)

      delete "/api/v1/auth/logout", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
