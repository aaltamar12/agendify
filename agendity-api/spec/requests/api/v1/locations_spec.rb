# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Locations", type: :request do
  describe "GET /api/v1/locations/countries" do
    it "returns a list of countries" do
      get "/api/v1/locations/countries"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
      expect(response.parsed_body["data"].first).to have_key("code")
    end
  end

  describe "GET /api/v1/locations/states" do
    it "returns states for a country" do
      get "/api/v1/locations/states", params: { country: "CO" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns empty without country param" do
      get "/api/v1/locations/states"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end
  end

  describe "GET /api/v1/locations/cities" do
    it "returns cities for a state" do
      get "/api/v1/locations/cities", params: { country: "CO", state: "ATL" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns empty without params" do
      get "/api/v1/locations/cities"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end
  end
end
