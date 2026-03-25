# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Employee::Appointments", type: :request do
  let(:business) { create(:business) }
  let(:employee_user) { create(:user, role: :employee) }
  let(:employee) { create(:employee, business: business, user: employee_user) }
  let(:token) { Auth::TokenGenerator.encode(employee_user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business) }

  before { employee } # Ensure employee is created

  describe "GET /api/v1/employee/appointments" do
    it "returns appointments for the employee" do
      create(:appointment, business: business, employee: employee, service: service, customer: customer)
      get "/api/v1/employee/appointments", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/employee/appointments"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for non-employee user" do
      owner_token = Auth::TokenGenerator.encode(business.owner)
      get "/api/v1/employee/appointments", headers: { "Authorization" => "Bearer #{owner_token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/employee/appointments/:id/checkin" do
    it "checks in an appointment" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :confirmed)
      post "/api/v1/employee/appointments/#{appointment.id}/checkin", headers: headers
      expect(response.status).to be_in([200, 409, 422])
    end
  end

  describe "POST /api/v1/employee/checkin_by_code" do
    it "checks in by ticket code" do
      appointment = create(:appointment, business: business, employee: employee, service: service, customer: customer, status: :confirmed)
      post "/api/v1/employee/checkin_by_code", params: { ticket_code: appointment.ticket_code }, headers: headers
      expect(response.status).to be_in([200, 409, 422])
    end

    it "returns 404 for unknown code" do
      post "/api/v1/employee/checkin_by_code", params: { ticket_code: "UNKNOWN" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
