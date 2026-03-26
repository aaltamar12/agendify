# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Businesses", type: :request do
  let(:business) { create(:business, :with_hours, status: :active) }

  describe "GET /api/v1/public/:slug" do
    it "returns the public business profile" do
      get "/api/v1/public/#{business.slug}"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("business")
      expect(data).to have_key("services")
      expect(data).to have_key("employees")
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/public/unknown-slug"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for inactive business" do
      inactive = create(:business, status: :suspended)
      get "/api/v1/public/#{inactive.slug}"
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/public/:slug/availability" do
    it "returns availability slots" do
      service = create(:service, business: business)
      get "/api/v1/public/#{business.slug}/availability",
          params: { service_id: service.id, date: Date.tomorrow.to_s }
      expect(response.status).to be_in([200, 422])
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/public/unknown-slug/availability"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/:slug/price_preview" do
    it "returns price preview" do
      service = create(:service, business: business, price: 30000)
      get "/api/v1/public/#{business.slug}/price_preview",
          params: { service_id: service.id, date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("base_price")
      expect(data).to have_key("adjusted_price")
    end
  end

  describe "GET /api/v1/public/:slug/price_calendar" do
    it "returns price calendar" do
      service = create(:service, business: business, price: 30000)
      get "/api/v1/public/#{business.slug}/price_calendar",
          params: { service_id: service.id, days: 7 }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns the correct number of days" do
      service = create(:service, business: business, price: 30000)
      get "/api/v1/public/#{business.slug}/price_calendar",
          params: { service_id: service.id, days: 5 }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(5)
    end

    it "clamps days to max 30" do
      service = create(:service, business: business, price: 30000)
      get "/api/v1/public/#{business.slug}/price_calendar",
          params: { service_id: service.id, days: 60 }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(30)
    end

    it "defaults to 14 days" do
      service = create(:service, business: business, price: 30000)
      get "/api/v1/public/#{business.slug}/price_calendar",
          params: { service_id: service.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(14)
    end
  end

  describe "GET /api/v1/public/:slug (response structure)" do
    it "includes business_hours, reviews, average_rating, and total_reviews" do
      get "/api/v1/public/#{business.slug}"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("business_hours")
      expect(data).to have_key("reviews")
      expect(data).to have_key("average_rating")
      expect(data).to have_key("total_reviews")
    end

    it "only returns active services and employees" do
      create(:service, business: business, active: true, name: "Active Service")
      create(:service, business: business, active: false, name: "Inactive Service")
      create(:employee, business: business, active: true, name: "Active Employee")
      create(:employee, business: business, active: false, name: "Inactive Employee")

      get "/api/v1/public/#{business.slug}"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      service_names = data["services"].map { |s| s["name"] }
      employee_names = data["employees"].map { |e| e["name"] }
      expect(service_names).to include("Active Service")
      expect(service_names).not_to include("Inactive Service")
      expect(employee_names).to include("Active Employee")
      expect(employee_names).not_to include("Inactive Employee")
    end
  end

  describe "GET /api/v1/public/:slug/price_preview with dynamic pricing" do
    it "returns adjusted price when dynamic pricing exists" do
      service = create(:service, business: business, price: 30000)
      create(:dynamic_pricing,
        business: business,
        service: service,
        price_adjustment_type: :percentage,
        adjustment_mode: :fixed_mode,
        adjustment_value: 20,
        start_date: Date.current - 1.day,
        end_date: Date.current + 30.days,
        status: :active,
        days_of_week: [])

      get "/api/v1/public/#{business.slug}/price_preview",
          params: { service_id: service.id, date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["has_dynamic_pricing"]).to be true
      expect(data["adjusted_price"].to_f).to eq(36000.0)
      expect(data["base_price"].to_f).to eq(30000.0)
    end

    it "returns base price when no dynamic pricing" do
      service = create(:service, business: business, price: 25000)
      get "/api/v1/public/#{business.slug}/price_preview",
          params: { service_id: service.id, date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["has_dynamic_pricing"]).to be false
      expect(data["adjusted_price"]).to eq(25000.0)
    end
  end

  describe "GET /api/v1/public/:slug/availability" do
    it "returns 403 for inactive business" do
      inactive = create(:business, status: :suspended)
      get "/api/v1/public/#{inactive.slug}/availability"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
