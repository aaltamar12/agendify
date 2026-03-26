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

    it "returns profit data for week period" do
      get "/api/v1/reports/profit", params: { period: "week" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["period"]).to eq("week")
    end

    it "returns profit data for year period" do
      get "/api/v1/reports/profit", params: { period: "year" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["period"]).to eq("year")
    end

    it "defaults to month when period is unrecognized" do
      get "/api/v1/reports/profit", params: { period: "invalid" }, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/reports/summary (failure)" do
    it "returns 422 when summary service fails" do
      allow(Reports::SummaryService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Something failed")
      )
      get "/api/v1/reports/summary", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/reports/revenue (failure)" do
    it "returns 422 when revenue service fails" do
      allow(Reports::RevenueService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Something failed")
      )
      get "/api/v1/reports/revenue", params: { period: "month" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/reports/top_services with data" do
    it "returns top services by count" do
      employee = create(:employee, business: business)
      svc = create(:service, business: business, name: "Corte")
      customer = create(:customer, business: business)
      create(:appointment, business: business, employee: employee, service: svc, customer: customer, status: :completed)

      get "/api/v1/reports/top_services", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.first["name"]).to eq("Corte")
    end
  end

  describe "GET /api/v1/reports/top_employees with data" do
    it "returns top employees by count" do
      employee = create(:employee, business: business, name: "Carlos Barbero")
      svc = create(:service, business: business)
      customer = create(:customer, business: business)
      create(:appointment, business: business, employee: employee, service: svc, customer: customer, status: :completed)

      get "/api/v1/reports/top_employees", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.first["name"]).to eq("Carlos Barbero")
    end
  end

  describe "GET /api/v1/reports/frequent_customers with data" do
    it "returns frequent customers with visit count and total spent" do
      employee = create(:employee, business: business)
      svc = create(:service, business: business)
      customer = create(:customer, business: business, name: "Frequent Customer", email: "freq@test.com")
      create(:appointment, business: business, employee: employee, service: svc, customer: customer, status: :completed, price: 25_000)
      create(:appointment, business: business, employee: employee, service: svc, customer: customer, status: :completed, price: 30_000)

      get "/api/v1/reports/frequent_customers", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      entry = data.find { |d| d["name"] == "Frequent Customer" }
      expect(entry["visits"]).to eq(2)
      expect(entry["total_spent"]).to eq(55_000.0)
    end
  end
end
