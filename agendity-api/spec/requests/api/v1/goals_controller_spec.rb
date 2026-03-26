# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Api::V1::GoalsController, type: :request do
  let(:user) { create(:user) }
  let(:business) { create(:business, owner: user) }
  let(:plan) { create(:plan, ai_features: true) }
  let(:headers) { auth_headers(user) }

  before do
    create(:subscription, business: business, plan: plan, status: :active)
  end

  describe "GET /api/v1/goals" do
    it "returns active goals" do
      goal = create(:business_goal, business: business, active: true)
      create(:business_goal, business: business, active: false)

      get "/api/v1/goals", headers: headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["id"]).to eq(goal.id)
    end
  end

  describe "POST /api/v1/goals" do
    let(:valid_params) do
      { goal: { goal_type: "monthly_sales", name: "Meta mensual", target_value: 5_000_000 } }
    end

    it "creates a goal" do
      post "/api/v1/goals", params: valid_params, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["goal_type"]).to eq("monthly_sales")
    end

    it "returns errors for invalid goal" do
      post "/api/v1/goals", params: { goal: { goal_type: "invalid", target_value: -1 } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  describe "PATCH /api/v1/goals/:id" do
    let!(:goal) { create(:business_goal, business: business) }

    it "updates a goal" do
      patch "/api/v1/goals/#{goal.id}", params: { goal: { name: "Updated" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Updated")
    end

    it "returns errors for invalid update" do
      patch "/api/v1/goals/#{goal.id}", params: { goal: { target_value: -1 } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  describe "DELETE /api/v1/goals/:id" do
    let!(:goal) { create(:business_goal, business: business) }

    it "destroys the goal" do
      expect {
        delete "/api/v1/goals/#{goal.id}", headers: headers
      }.to change(BusinessGoal, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/goals/progress" do
    it "returns progress when service succeeds" do
      result = OpenStruct.new(success?: true, data: { goals: [] })
      allow(Intelligence::GoalProgressService).to receive(:call).and_return(result)

      get "/api/v1/goals/progress", headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "returns error when service fails" do
      result = OpenStruct.new(success?: false, error: "No goals configured")
      allow(Intelligence::GoalProgressService).to receive(:call).and_return(result)

      get "/api/v1/goals/progress", headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("No goals configured")
    end
  end

  context "when business does not have ai_features" do
    before do
      business.subscriptions.destroy_all
      no_ai_plan = create(:plan, ai_features: false)
      create(:subscription, business: business, plan: no_ai_plan, status: :active)
    end

    it "returns forbidden for index" do
      get "/api/v1/goals", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("Plan Inteligente")
    end
  end
end
