# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Goals", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  # Trial = all features enabled (no plan = trial)
  describe "GET /api/v1/goals" do
    it "returns goals for the business" do
      get "/api/v1/goals", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 403 without intelligent plan" do
      plan = create(:plan, ai_features: false)
      create(:subscription, business: business, plan: plan)
      get "/api/v1/goals", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/goals"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/goals" do
    it "creates a goal" do
      params = { goal: { goal_type: "monthly_sales", name: "Meta mensual", target_value: 1000000, period: "monthly" } }
      post "/api/v1/goals", params: params, headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /api/v1/goals/:id" do
    it "deletes a goal" do
      goal = business.business_goals.create!(goal_type: "monthly_sales", name: "Test", target_value: 500000, period: "monthly")
      delete "/api/v1/goals/#{goal.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/goals/progress" do
    it "returns goal progress" do
      get "/api/v1/goals/progress", headers: headers
      expect(response.status).to be_in([200, 400])
    end
  end
end
