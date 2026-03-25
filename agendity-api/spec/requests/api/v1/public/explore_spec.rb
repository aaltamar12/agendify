# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Explore", type: :request do
  describe "GET /api/v1/public/explore" do
    it "returns active businesses" do
      create(:business, status: :active)
      get "/api/v1/public/explore"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "filters by search term" do
      create(:business, status: :active, name: "Barbería Elite")
      get "/api/v1/public/explore", params: { search: "Elite" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by city" do
      create(:business, status: :active, city: "Barranquilla")
      get "/api/v1/public/explore", params: { city: "Barranquilla" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/public/cities" do
    it "returns cities with active businesses" do
      create(:business, status: :active, city: "Barranquilla")
      get "/api/v1/public/cities"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end
end
