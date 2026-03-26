# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/v1/auth/login" do
    it "returns token on valid credentials" do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["token"]).to be_present
    end

    it "returns 401 on invalid credentials" do
      post "/api/v1/auth/login", params: { email: user.email, password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/register" do
    it "creates a new user and business" do
      params = {
        name: "Test User",
        email: "newuser@test.com",
        password: "password123",
        password_confirmation: "password123",
        phone: "3001234567",
        business_name: "Mi Barbería",
        business_type: "barbershop",
        terms_accepted: true
      }
      post "/api/v1/auth/register", params: params
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["token"]).to be_present
    end

    it "returns 422 with invalid params" do
      post "/api/v1/auth/register", params: {
        name: "",
        email: "",
        password: "",
        password_confirmation: ""
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    it "returns 401 with invalid refresh token" do
      post "/api/v1/auth/refresh", params: { refresh_token: "invalid" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns current user info" do
      get "/api/v1/auth/me", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(user.id)
    end

    it "returns 401 without token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "returns 401 without token" do
      # Warden JWT middleware intercepts this route for revocation;
      # without a valid Devise-signed token it returns 401 regardless.
      delete "/api/v1/auth/logout"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
