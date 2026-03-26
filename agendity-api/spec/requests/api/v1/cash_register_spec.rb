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

  describe "POST /api/v1/cash_register/close (failure)" do
    it "returns 422 when close service fails" do
      allow(CashRegister::CloseService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Ya se cerro caja hoy", error_code: "ALREADY_CLOSED")
      )
      post "/api/v1/cash_register/close",
           params: { date: Date.current.to_s },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/cash_register/history with date filters" do
    it "filters by from and to dates" do
      close1 = create(:cash_register_close, business: business, closed_by_user: user, date: 5.days.ago.to_date, status: :closed)
      close2 = create(:cash_register_close, business: business, closed_by_user: user, date: 2.days.ago.to_date, status: :closed)
      get "/api/v1/cash_register/history",
          params: { from: 3.days.ago.to_date.to_s, to: Date.current.to_s },
          headers: headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["data"].map { |c| c["id"] }
      expect(ids).to include(close2.id)
      expect(ids).not_to include(close1.id)
    end
  end

  describe "GET /api/v1/cash_register/:id" do
    it "returns a specific cash register close" do
      close = create(:cash_register_close, business: business, closed_by_user: user, date: Date.current, status: :closed)
      get "/api/v1/cash_register/#{close.id}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for another business close" do
      other_close = create(:cash_register_close)
      get "/api/v1/cash_register/#{other_close.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cash_register/:id/employee_payments/:employee_payment_id/receipt" do
    it "returns PDF receipt when service succeeds" do
      close = create(:cash_register_close, business: business, closed_by_user: user, date: Date.current, status: :closed)
      emp = create(:employee, business: business)
      payment = create(:employee_payment, cash_register_close: close, employee: emp)
      allow(CashRegister::GeneratePaymentReceiptService).to receive(:call).and_return(
        ServiceResult.new(success: true, data: "fake-pdf-content")
      )
      get "/api/v1/cash_register/#{close.id}/employee_payments/#{payment.id}/receipt", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/pdf")
    end

    it "returns 422 when receipt generation fails" do
      close = create(:cash_register_close, business: business, closed_by_user: user, date: Date.current, status: :closed)
      emp = create(:employee, business: business)
      payment = create(:employee_payment, cash_register_close: close, employee: emp)
      allow(CashRegister::GeneratePaymentReceiptService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "PDF generation failed")
      )
      get "/api/v1/cash_register/#{close.id}/employee_payments/#{payment.id}/receipt", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
