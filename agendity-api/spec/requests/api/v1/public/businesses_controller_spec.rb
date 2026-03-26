# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Api::V1::Public::BusinessesController, type: :request do
  let(:business) { create(:business, :with_hours, status: :active) }
  let(:service) { create(:service, business: business, active: true) }
  let!(:employee) { create(:employee, business: business, active: true) }

  describe "GET /api/v1/public/:slug" do
    it "returns the business public profile" do
      service # create
      get "/api/v1/public/#{business.slug}"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["business"]).to be_present
      expect(data["services"]).to be_an(Array)
      expect(data["employees"]).to be_an(Array)
      expect(data["business_hours"]).to be_an(Array)
    end

    it "returns forbidden for inactive business" do
      business.update!(status: :suspended)

      get "/api/v1/public/#{business.slug}"

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("no est")
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/public/unknown-slug-xyz"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/:slug/availability" do
    it "returns availability when service succeeds" do
      result = OpenStruct.new(success?: true, data: { slots: [] })
      allow(Bookings::AvailabilityService).to receive(:call).and_return(result)

      get "/api/v1/public/#{business.slug}/availability", params: { date: Date.tomorrow.to_s, service_id: service.id }

      expect(response).to have_http_status(:ok)
    end

    it "returns error when service fails" do
      result = OpenStruct.new(success?: false, error: "Invalid date", details: { date: "is required" })
      allow(Bookings::AvailabilityService).to receive(:call).and_return(result)

      get "/api/v1/public/#{business.slug}/availability", params: { date: "invalid" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Invalid date")
    end

    it "returns forbidden for inactive business" do
      business.update!(status: :inactive)

      get "/api/v1/public/#{business.slug}/availability"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/public/:slug/price_preview" do
    it "returns base price when no dynamic pricing" do
      get "/api/v1/public/#{business.slug}/price_preview", params: { service_id: service.id, date: Date.tomorrow.to_s }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["has_dynamic_pricing"]).to be false
      expect(data["base_price"]).to eq(service.price.to_f)
      expect(data["adjusted_price"]).to eq(service.price.to_f)
    end

    it "returns adjusted price when dynamic pricing applies" do
      # Create a dynamic pricing that applies on the target date
      target_date = Date.tomorrow
      pricing = create(:dynamic_pricing,
        business: business,
        service: service,
        start_date: target_date - 1.day,
        end_date: target_date + 1.day,
        adjustment_value: 20,
        days_of_week: []
      )

      get "/api/v1/public/#{business.slug}/price_preview", params: { service_id: service.id, date: target_date.to_s }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["has_dynamic_pricing"]).to be true
      expect(data["dynamic_pricing_name"]).to eq(pricing.name)
    end

    it "handles invalid date gracefully" do
      get "/api/v1/public/#{business.slug}/price_preview", params: { service_id: service.id, date: "invalid" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/public/:slug/price_calendar" do
    it "returns calendar for the requested days" do
      get "/api/v1/public/#{business.slug}/price_calendar", params: {
        service_id: service.id,
        from: Date.tomorrow.to_s,
        days: 3
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
      expect(data.first).to include("date", "base_price", "adjusted_price", "closed")
    end

    it "defaults to 14 days when no days param" do
      get "/api/v1/public/#{business.slug}/price_calendar", params: { service_id: service.id }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(14)
    end

    it "clamps days to max 30" do
      get "/api/v1/public/#{business.slug}/price_calendar", params: {
        service_id: service.id,
        days: 100
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(30)
    end

    it "includes dynamic pricing adjustments in calendar" do
      # Create a dynamic pricing that applies to all days
      create(:dynamic_pricing,
        business: business,
        service: service,
        price_adjustment_type: :percentage,
        adjustment_mode: :fixed_mode,
        adjustment_value: 15,
        start_date: Date.current - 1.day,
        end_date: Date.current + 30.days,
        days_of_week: [],
        status: :active)

      get "/api/v1/public/#{business.slug}/price_calendar", params: {
        service_id: service.id,
        from: Date.tomorrow.to_s,
        days: 3
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      open_day = data.find { |d| !d["closed"] }
      if open_day
        expect(open_day["has_dynamic_pricing"]).to be true
        expect(open_day["adjusted_price"]).not_to eq(open_day["base_price"])
      end
    end
  end
end
