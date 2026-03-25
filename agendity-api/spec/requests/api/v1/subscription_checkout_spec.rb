# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::SubscriptionCheckout", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before do
    allow(SiteConfig).to receive(:get).and_return("test_value")
  end

  describe "GET /api/v1/subscription/plans" do
    it "returns available plans" do
      create(:plan, name: "Básico")
      get "/api/v1/subscription/plans", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/subscription/payment_info" do
    it "returns payment information" do
      get "/api/v1/subscription/payment_info", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("nequi")
    end
  end

  describe "POST /api/v1/subscription/checkout" do
    it "submits checkout" do
      plan = create(:plan)
      post "/api/v1/subscription/checkout",
           params: { plan_id: plan.id },
           headers: headers
      expect(response.status).to be_in([201, 422])
    end

    it "returns 401 without token" do
      post "/api/v1/subscription/checkout", params: { plan_id: 1 }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/subscription/status" do
    it "returns subscription status" do
      get "/api/v1/subscription/status", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("trial_active")
    end
  end
end
