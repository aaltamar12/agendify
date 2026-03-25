# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Businesses", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/business" do
    it "returns the current business" do
      get "/api/v1/business", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(business.id)
    end

    it "returns 401 without token" do
      get "/api/v1/business"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/business" do
    it "updates the business" do
      patch "/api/v1/business", params: { business: { name: "Updated Name" } }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Updated Name")
    end

    it "returns 401 without token" do
      patch "/api/v1/business", params: { business: { name: "X" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/business/upload_logo" do
    it "returns 422 without file" do
      post "/api/v1/business/upload_logo", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/upload_cover" do
    it "returns 422 without file" do
      post "/api/v1/business/upload_cover", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/business/cover_gallery" do
    it "returns gallery photos" do
      allow(PexelsService).to receive(:search).and_return([])
      get "/api/v1/business/cover_gallery", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/business/select_cover" do
    it "returns 422 without URL" do
      post "/api/v1/business/select_cover", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/onboarding" do
    it "completes onboarding" do
      params = {
        name: business.name,
        business_type: "barbershop",
        phone: "3001234567",
        address: "Calle 1",
        city: "Barranquilla",
        state: "ATL",
        country: "CO"
      }
      post "/api/v1/business/onboarding", params: params, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
