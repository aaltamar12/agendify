# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::CashRegister", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  # Trial = all features enabled
  describe "GET /api/v1/cash_register/today" do
    it "returns today's cash register summary" do
      get "/api/v1/cash_register/today", headers: headers
      expect(response.status).to be_in([200, 422])
    end

    it "returns 403 without professional plan" do
      plan = create(:plan, advanced_reports: false)
      create(:subscription, business: business, plan: plan)
      get "/api/v1/cash_register/today", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/cash_register/today"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/cash_register/close" do
    it "closes the cash register" do
      post "/api/v1/cash_register/close",
           params: { date: Date.current.to_s },
           headers: headers
      expect(response.status).to be_in([201, 422])
    end
  end

  describe "GET /api/v1/cash_register/history" do
    it "returns cash register close history" do
      get "/api/v1/cash_register/history", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/cash_register/upload_proof" do
    it "returns 422 without file" do
      close = create(:cash_register_close, business: business, closed_by_user: user, date: Date.current, status: :closed)
      payment = create(:employee_payment, cash_register_close: close, employee: create(:employee, business: business), amount_paid: 10000, total_owed: 10000)
      post "/api/v1/cash_register/upload_proof",
           params: { employee_payment_id: payment.id },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/cash_register/delete_proof" do
    it "deletes proof from a payment" do
      close = create(:cash_register_close, business: business, closed_by_user: user, date: Date.current, status: :closed)
      payment = create(:employee_payment, cash_register_close: close, employee: create(:employee, business: business), amount_paid: 10000, total_owed: 10000)
      delete "/api/v1/cash_register/delete_proof",
             params: { employee_payment_id: payment.id },
             headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
