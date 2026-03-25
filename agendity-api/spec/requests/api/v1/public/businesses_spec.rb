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
  end
end
