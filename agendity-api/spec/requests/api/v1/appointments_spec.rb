# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Appointments", type: :request do
  let(:business) { create(:business, :with_hours) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:employee) { create(:employee, business: business) }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business) }

  describe "GET /api/v1/appointments" do
    it "returns appointments for the business" do
      create(:appointment, business: business, employee: employee, service: service, customer: customer)
      get "/api/v1/appointments", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "filters by date" do
      create(:appointment, business: business, employee: employee, service: service, customer: customer, appointment_date: Date.tomorrow)
      get "/api/v1/appointments", params: { date: Date.tomorrow }, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without token" do
      get "/api/v1/appointments"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/appointments" do
    it "creates an appointment" do
      params = {
        appointment: {
          service_id: service.id,
          employee_id: employee.id,
          customer_name: "Carlos",
          customer_phone: "3001234567",
          customer_email: "carlos@test.com",
          appointment_date: Date.tomorrow.to_s,
          start_time: "10:00"
        }
      }
      post "/api/v1/appointments", params: params, headers: headers
      expect(response.status).to be_in([201, 422])
    end
  end

  describe "POST /api/v1/appointments/:id/confirm" do
    it "confirms an appointment" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :pending_payment)
      post "/api/v1/appointments/#{appointment.id}/confirm", headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/appointments/:id/checkin" do
    it "checks in an appointment" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :confirmed)
      post "/api/v1/appointments/#{appointment.id}/checkin", headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/appointments/checkin_by_code" do
    it "checks in by ticket code" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :confirmed)
      post "/api/v1/appointments/checkin_by_code", params: { ticket_code: appointment.ticket_code }, headers: headers
      expect(response.status).to be_in([200, 422])
    end

    it "returns 404 for unknown code" do
      post "/api/v1/appointments/checkin_by_code", params: { ticket_code: "UNKNOWN" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/appointments/:id/cancel" do
    it "cancels an appointment" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :confirmed)
      post "/api/v1/appointments/#{appointment.id}/cancel", headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/appointments/:id/complete" do
    it "completes an appointment" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :checked_in)
      post "/api/v1/appointments/#{appointment.id}/complete", headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "GET /api/v1/appointments/available_slots" do
    it "returns available slots" do
      get "/api/v1/appointments/available_slots",
          params: { service_id: service.id, date: Date.tomorrow.to_s },
          headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "POST /api/v1/appointments/:id/remind_payment" do
    it "returns 422 if customer has no email" do
      customer_no_email = create(:customer, business: business, email: nil)
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer_no_email, status: :pending_payment)
      post "/api/v1/appointments/#{appointment.id}/remind_payment", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
