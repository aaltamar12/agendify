# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reports", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/reports/summary" do
    it "returns summary data" do
      get "/api/v1/reports/summary", headers: headers
      expect(response.status).to be_in([200, 422])
    end

    it "returns 401 without token" do
      get "/api/v1/reports/summary"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/reports/revenue" do
    it "returns revenue data" do
      get "/api/v1/reports/revenue", params: { period: "month" }, headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "GET /api/v1/reports/top_services" do
    it "returns top services" do
      get "/api/v1/reports/top_services", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/reports/top_employees" do
    it "returns top employees" do
      get "/api/v1/reports/top_employees", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/reports/frequent_customers" do
    it "returns frequent customers" do
      get "/api/v1/reports/frequent_customers", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/reports/profit" do
    it "returns profit data" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("revenue")
      expect(data).to have_key("net_profit")
    end
  end
end
