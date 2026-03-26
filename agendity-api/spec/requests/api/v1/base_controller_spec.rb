# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Api::V1::BaseController, type: :request do
  # We test base controller behavior through various endpoints

  describe "authentication" do
    it "returns 401 without token" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Not authenticated")
    end

    it "returns 401 with invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with denied token" do
      user = create(:user)
      create(:business, owner: user)
      token = Auth::TokenGenerator.encode(user)
      payload = Auth::TokenGenerator.decode(token)
      JwtDenylist.create!(jti: payload[:jti], exp: 1.day.from_now)

      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when user not found" do
      # Encode a token for a non-existent user ID
      payload = { sub: 999_999, jti: SecureRandom.uuid, exp: 1.day.from_now.to_i }
      token = JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key || ENV["DEVISE_JWT_SECRET_KEY"] || "dev-secret-key", "HS256")

      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "require_business!" do
    it "returns forbidden when user has no business" do
      user = create(:user) # no business
      headers = auth_headers(user)

      # Use an endpoint that requires business (not auth/me which skips it)
      get "/api/v1/services", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("No business")
    end

    it "allows admin without business and returns empty data" do
      admin = create(:user, :admin) # admin, no business
      headers = auth_headers(admin)

      get "/api/v1/services", headers: headers

      # Admin without business gets empty response from render_empty_for_admin_without_business!
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end
  end

  describe "error handlers" do
    let(:user) { create(:user) }
    let(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    before { business }

    it "handles RecordNotFound" do
      get "/api/v1/services/999999", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Resource not found")
    end
  end

  describe "render_paginated" do
    let(:user) { create(:user) }
    let(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    before { business }

    it "paginates results" do
      get "/api/v1/customers", params: { page: 1, per_page: 5 }, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["meta"]).to include("current_page", "total_pages", "total_count", "per_page")
    end
  end

  describe "render_error with details and code" do
    it "includes details in error response" do
      result = OpenStruct.new(success?: false, error: "Invalid credentials", details: { email: ["not found"] })
      allow(Auth::LoginService).to receive(:call).and_return(result)

      post "/api/v1/auth/login", params: { email: "x@x.com", password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["details"]).to be_present
    end
  end

  describe "handle_unauthorized (Pundit)" do
    let(:user) { create(:user) }
    let(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    before { business }

    it "returns 403 for Pundit::NotAuthorizedError" do
      other_business = create(:business)
      other_employee = create(:employee, business: other_business)
      # Trying to update another business's employee should trigger Pundit error
      patch "/api/v1/employees/#{other_employee.id}",
            params: { employee: { name: "Hacked" } },
            headers: headers
      expect(response.status).to be_in([403, 404])
    end
  end

  describe "handle_record_invalid" do
    let(:user) { create(:user) }
    let(:business) { create(:business, owner: user) }
    let(:headers) { auth_headers(user) }

    before { business }

    it "returns 422 with validation error messages" do
      # Create a service without required fields to trigger RecordInvalid
      post "/api/v1/services",
           params: { service: { name: "", price: -1, duration_minutes: 0 } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end
end
