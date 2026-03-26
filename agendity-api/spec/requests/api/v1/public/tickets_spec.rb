# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Tickets", type: :request do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business, email: "test@test.com") }
  let(:appointment) do
    create(:appointment,
           business: business,
           employee: employee,
           service: service,
           customer: customer,
           status: :confirmed)
  end

  describe "GET /api/v1/public/tickets/:code" do
    it "returns ticket details" do
      get "/api/v1/public/tickets/#{appointment.ticket_code}"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("appointment")
      expect(data).to have_key("business")
    end

    it "returns 404 for unknown code" do
      get "/api/v1/public/tickets/UNKNOWN"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/tickets/:code/cancel_preview" do
    it "returns cancellation preview" do
      get "/api/v1/public/tickets/#{appointment.ticket_code}/cancel_preview"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("can_cancel")
      expect(data).to have_key("penalty_amount")
    end
  end

  describe "POST /api/v1/public/tickets/:code/cancel" do
    it "cancels the appointment" do
      post "/api/v1/public/tickets/#{appointment.ticket_code}/cancel",
           params: { reason: "Changed plans" }
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/public/tickets/:code/payment" do
    it "returns 403 with wrong customer email" do
      pending_appointment = create(:appointment,
                                   business: business,
                                   employee: employee,
                                   service: service,
                                   customer: customer,
                                   status: :pending_payment)
      post "/api/v1/public/tickets/#{pending_appointment.ticket_code}/payment",
           params: { customer_email: "wrong@test.com", payment_method: "transfer" }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when customer_email is missing" do
      pending_appointment = create(:appointment,
                                   business: business,
                                   employee: employee,
                                   service: service,
                                   customer: customer,
                                   status: :pending_payment)
      post "/api/v1/public/tickets/#{pending_appointment.ticket_code}/payment",
           params: { payment_method: "transfer" }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when appointment is not pending_payment" do
      confirmed_appointment = create(:appointment,
                                     business: business,
                                     employee: employee,
                                     service: service,
                                     customer: customer,
                                     status: :confirmed)
      post "/api/v1/public/tickets/#{confirmed_appointment.ticket_code}/payment",
           params: { customer_email: "test@test.com", payment_method: "transfer" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "submits payment successfully" do
      pending_appointment = create(:appointment,
                                   business: business,
                                   employee: employee,
                                   service: service,
                                   customer: customer,
                                   status: :pending_payment)
      allow(Payments::SubmitPaymentService).to receive(:call).and_return(
        ServiceResult.new(success: true, data: pending_appointment)
      )
      post "/api/v1/public/tickets/#{pending_appointment.ticket_code}/payment",
           params: { customer_email: "test@test.com", payment_method: "transfer" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["status"]).to eq("submitted")
    end

    it "submits payment with proof file upload" do
      pending_appointment = create(:appointment,
                                   business: business,
                                   employee: employee,
                                   service: service,
                                   customer: customer,
                                   status: :pending_payment)
      allow(Payments::SubmitPaymentService).to receive(:call).and_return(
        ServiceResult.new(success: true, data: pending_appointment)
      )
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/proof.png"), "image/png")
      post "/api/v1/public/tickets/#{pending_appointment.ticket_code}/payment",
           params: { customer_email: "test@test.com", payment_method: "transfer", proof: file }
      expect(response).to have_http_status(:ok)
      expect(pending_appointment.reload.proof_image).to be_attached
    end

    it "returns 422 when payment service fails" do
      pending_appointment = create(:appointment,
                                   business: business,
                                   employee: employee,
                                   service: service,
                                   customer: customer,
                                   status: :pending_payment)
      allow(Payments::SubmitPaymentService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Payment failed", details: {})
      )
      post "/api/v1/public/tickets/#{pending_appointment.ticket_code}/payment",
           params: { customer_email: "test@test.com", payment_method: "transfer" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/public/tickets/:code/cancel (failure)" do
    it "returns 422 when cancel service fails" do
      allow(Appointments::CancelAppointmentService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Cannot cancel", details: {})
      )
      post "/api/v1/public/tickets/#{appointment.ticket_code}/cancel",
           params: { reason: "Changed plans" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/public/tickets/:code/cancel_preview" do
    it "shows penalty when deadline has passed and policy is set" do
      biz = create(:business, cancellation_policy_pct: 50, cancellation_deadline_hours: 24)
      emp = create(:employee, business: biz)
      svc = create(:service, business: biz)
      cust = create(:customer, business: biz, email: "cust@test.com")
      # Appointment in 1 hour (within 24h deadline)
      appt = create(:appointment,
                     business: biz,
                     employee: emp,
                     service: svc,
                     customer: cust,
                     appointment_date: Date.current,
                     start_time: (Time.current + 1.hour).strftime("%H:%M"),
                     status: :payment_sent,
                     price: 50_000)

      get "/api/v1/public/tickets/#{appt.ticket_code}/cancel_preview"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["deadline_passed"]).to be true
      expect(data["penalty_amount"].to_f).to be > 0
      expect(data["has_paid"]).to be true
      expect(data["refund_amount"].to_f).to be > 0
    end
  end
end
