# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reconciliation", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/reconciliation/check" do
    it "returns reconciliation results (trial has all features)" do
      get "/api/v1/reconciliation/check", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("cash_register")
      expect(data).to have_key("credits")
    end

    it "returns 403 without intelligent plan" do
      plan = create(:plan, ai_features: false)
      create(:subscription, business: business, plan: plan)
      get "/api/v1/reconciliation/check", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/reconciliation/check"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
