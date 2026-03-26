# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::EmployeeBalanceAdjustments", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/employee_balance_adjustments" do
    it "returns success" do
      create(:employee_balance_adjustment)
      get "/admin/employee_balance_adjustments"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/employee_balance_adjustments/:id" do
    it "returns success" do
      adjustment = create(:employee_balance_adjustment)
      get "/admin/employee_balance_adjustments/#{adjustment.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
