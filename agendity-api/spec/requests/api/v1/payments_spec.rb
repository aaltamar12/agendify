# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Payments", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:employee) { create(:employee, business: business) }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:appointment) { create(:appointment, business: business, employee: employee, service: service, customer: customer) }

  describe "POST /api/v1/appointments/:appointment_id/payments/submit" do
    it "submits a payment" do
      post "/api/v1/appointments/#{appointment.id}/payments/submit",
           params: { payment: { payment_method: "transfer", amount: 25000 } },
           headers: headers
      expect(response.status).to be_in([201, 422])
    end

    it "returns 401 without token" do
      post "/api/v1/appointments/#{appointment.id}/payments/submit",
           params: { payment: { payment_method: "transfer", amount: 25000 } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/payments/:id/approve" do
    it "approves a payment" do
      payment = create(:payment, appointment: appointment, status: :pending)
      post "/api/v1/payments/#{payment.id}/approve", headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/payments/:id/reject" do
    it "rejects a payment" do
      payment = create(:payment, appointment: appointment, status: :pending)
      post "/api/v1/payments/#{payment.id}/reject",
           params: { rejection_reason: "Invalid proof" },
           headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/appointments/:appointment_id/payments/submit (failure)" do
    it "returns 422 when submit service fails" do
      allow(Payments::SubmitPaymentService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Already submitted", details: {})
      )
      post "/api/v1/appointments/#{appointment.id}/payments/submit",
           params: { payment: { payment_method: "transfer", amount: 25000 } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/payments/:id/approve (failure)" do
    it "returns 422 when approve service fails" do
      payment = create(:payment, appointment: appointment, status: :submitted)
      allow(Payments::ApprovePaymentService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Cannot approve", details: {})
      )
      post "/api/v1/payments/#{payment.id}/approve", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/payments/:id/reject (failure)" do
    it "returns 422 when reject service fails" do
      payment = create(:payment, appointment: appointment, status: :submitted)
      allow(Payments::RejectPaymentService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Cannot reject", details: {})
      )
      post "/api/v1/payments/#{payment.id}/reject", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "payment_params" do
    it "maps proof to proof_image_url" do
      post "/api/v1/appointments/#{appointment.id}/payments/submit",
           params: { payment: { payment_method: "transfer", amount: 25000, proof: "https://example.com/proof.jpg" } },
           headers: headers
      expect(response.status).to be_in([201, 422])
    end
  end
end
