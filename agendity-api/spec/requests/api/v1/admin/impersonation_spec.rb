# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Impersonation", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:owner_user) { create(:user, role: :owner) }
  let(:business) { create(:business, owner: owner_user) }

  let(:admin_token) { Auth::TokenGenerator.encode(admin_user) }
  let(:owner_token) { Auth::TokenGenerator.encode(owner_user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:owner_headers) { { "Authorization" => "Bearer #{owner_token}" } }

  describe "POST /api/v1/admin/impersonate" do
    it "returns impersonation token for the business owner" do
      post "/api/v1/admin/impersonate",
           params: { business_id: business.id },
           headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["impersonating"]).to be true
      expect(data["token"]).to be_present
      expect(data["admin_token"]).to eq(admin_token)
      expect(data["user"]["id"]).to eq(owner_user.id)
      expect(data["business"]["id"]).to eq(business.id)
    end

    it "returns 403 for non-admin users" do
      post "/api/v1/admin/impersonate",
           params: { business_id: business.id },
           headers: owner_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without authentication" do
      post "/api/v1/admin/impersonate",
           params: { business_id: business.id }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for non-existent business" do
      post "/api/v1/admin/impersonate",
           params: { business_id: 999_999 },
           headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/admin/stop_impersonation" do
    it "returns success message for admin" do
      post "/api/v1/admin/stop_impersonation", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["message"]).to eq("Impersonación finalizada")
    end

    it "returns 403 for non-admin users" do
      post "/api/v1/admin/stop_impersonation", headers: owner_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
