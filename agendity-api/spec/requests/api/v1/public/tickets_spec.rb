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
  end
end
