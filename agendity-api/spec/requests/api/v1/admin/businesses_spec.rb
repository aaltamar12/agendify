# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Businesses", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:owner_user) { create(:user, role: :owner) }
  let(:admin_token) { Auth::TokenGenerator.encode(admin_user) }
  let(:owner_token) { Auth::TokenGenerator.encode(owner_user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:owner_headers) { { "Authorization" => "Bearer #{owner_token}" } }

  before do
    create(:business, name: "Barbería Elite", owner: create(:user))
    create(:business, name: "Salón Glamour", owner: create(:user))
    create(:business, name: "Barbería Plus", owner: create(:user))
  end

  describe "GET /api/v1/admin/businesses" do
    it "returns all businesses for admin" do
      get "/api/v1/admin/businesses", headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end

    it "filters businesses by search term" do
      get "/api/v1/admin/businesses",
          params: { search: "Barbería" },
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
      expect(data.map { |b| b["name"] }).to all(include("Barbería"))
    end

    it "returns business fields: id, name, slug, business_type" do
      get "/api/v1/admin/businesses", headers: auth_headers

      data = response.parsed_body["data"]
      first = data.first
      expect(first.keys).to match_array(%w[id name slug business_type status plan_name independent])
    end

    it "returns 403 for non-admin users" do
      get "/api/v1/admin/businesses", headers: owner_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without authentication" do
      get "/api/v1/admin/businesses"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
