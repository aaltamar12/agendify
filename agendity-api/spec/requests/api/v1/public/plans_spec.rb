# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Plans", type: :request do
  describe "GET /api/v1/public/plans" do
    it "returns all plans ordered by price" do
      plan_a = create(:plan, name: "Basico", price_monthly: 29_900)
      plan_b = create(:plan, name: "Pro", price_monthly: 49_900)

      get "/api/v1/public/plans"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to be_an(Array)
      expect(data.size).to eq(2)
      expect(data.first["name"]).to eq("Basico")
      expect(data.first["price_monthly"]).to eq(29_900.0)
      expect(data.first).to have_key("max_employees")
      expect(data.first).to have_key("max_services")
      expect(data.first).to have_key("features")
      expect(data.first).to have_key("price_monthly_usd")
    end

    it "returns empty array when no plans exist" do
      get "/api/v1/public/plans"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end

    it "does not require authentication" do
      get "/api/v1/public/plans"
      expect(response).to have_http_status(:ok)
    end

    it "includes features array" do
      create(:plan, features: ["feature1", "feature2"])
      get "/api/v1/public/plans"
      expect(response.parsed_body["data"].first["features"]).to eq(["feature1", "feature2"])
    end

    it "defaults features to empty array when nil" do
      plan = create(:plan)
      plan.update_column(:features, nil)
      get "/api/v1/public/plans"
      expect(response.parsed_body["data"].first["features"]).to eq([])
    end
  end
end
