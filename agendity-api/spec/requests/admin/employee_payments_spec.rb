# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::EmployeePayments", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/employee_payments" do
    it "returns success" do
      create(:employee_payment)
      get "/admin/employee_payments"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/employee_payments/:id" do
    it "returns success" do
      payment = create(:employee_payment)
      get "/admin/employee_payments/#{payment.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
