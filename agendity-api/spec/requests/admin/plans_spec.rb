# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Plans", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:plan) { create(:plan) }

  before { admin_login(admin) }

  describe "GET /admin/plans" do
    it "returns success" do
      get admin_plans_path
      expect(response).to have_http_status(:success)
    end

    it "displays the plan" do
      get admin_plans_path
      expect(response.body).to include(plan.name)
    end
  end

  describe "GET /admin/plans/:id" do
    it "returns success" do
      get admin_plan_path(plan)
      expect(response).to have_http_status(:success)
    end

    it "displays plan details" do
      get admin_plan_path(plan)
      expect(response.body).to include(plan.name)
    end
  end

  describe "GET /admin/plans/new" do
    it "returns success" do
      get new_admin_plan_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/plans/:id/edit" do
    it "returns success" do
      get edit_admin_plan_path(plan)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/plans" do
    it "creates a new plan" do
      expect {
        post admin_plans_path, params: {
          plan: {
            name: "Premium Test Plan",
            price_monthly: 99_900,
            max_employees: 10,
            max_services: 20,
            ai_features: true,
            ticket_digital: true
          }
        }
      }.to change(Plan, :count).by(1)
    end
  end

  describe "PATCH /admin/plans/:id" do
    it "updates the plan" do
      patch admin_plan_path(plan), params: {
        plan: { name: "Updated Plan Name" }
      }
      expect(plan.reload.name).to eq("Updated Plan Name")
    end
  end
end
