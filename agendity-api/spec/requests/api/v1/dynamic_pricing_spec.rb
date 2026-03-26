# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::DynamicPricing", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  # Trial = all features enabled
  describe "GET /api/v1/dynamic_pricing" do
    it "returns dynamic pricings" do
      create(:dynamic_pricing, business: business)
      get "/api/v1/dynamic_pricing", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 403 without professional plan" do
      plan = create(:plan, advanced_reports: false)
      create(:subscription, business: business, plan: plan)
      get "/api/v1/dynamic_pricing", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/dynamic_pricing"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/dynamic_pricing" do
    it "creates a dynamic pricing" do
      service = create(:service, business: business)
      params = {
        dynamic_pricing: {
          name: "Descuento Lunes",
          service_id: service.id,
          start_date: Date.current.to_s,
          end_date: (Date.current + 30).to_s,
          price_adjustment_type: "percentage",
          adjustment_mode: "fixed_mode",
          adjustment_value: -10
        }
      }
      post "/api/v1/dynamic_pricing", params: params, headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/dynamic_pricing/:id" do
    it "updates a dynamic pricing" do
      pricing = create(:dynamic_pricing, business: business)
      patch "/api/v1/dynamic_pricing/#{pricing.id}",
            params: { dynamic_pricing: { name: "Updated" } },
            headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /api/v1/dynamic_pricing/:id/accept" do
    it "accepts a suggested pricing" do
      pricing = create(:dynamic_pricing, :suggested, business: business)
      patch "/api/v1/dynamic_pricing/#{pricing.id}/accept", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /api/v1/dynamic_pricing/:id/reject" do
    it "rejects a suggested pricing" do
      pricing = create(:dynamic_pricing, :suggested, business: business)
      patch "/api/v1/dynamic_pricing/#{pricing.id}/reject", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/dynamic_pricing/:id" do
    it "deletes a dynamic pricing" do
      pricing = create(:dynamic_pricing, business: business)
      delete "/api/v1/dynamic_pricing/#{pricing.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/dynamic_pricing (failure)" do
    it "returns 422 when creation fails" do
      post "/api/v1/dynamic_pricing",
           params: { dynamic_pricing: { name: "", start_date: "", end_date: "" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/dynamic_pricing/:id (failure)" do
    it "returns 422 when update fails" do
      pricing = create(:dynamic_pricing, business: business)
      patch "/api/v1/dynamic_pricing/#{pricing.id}",
            params: { dynamic_pricing: { name: "" } },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
