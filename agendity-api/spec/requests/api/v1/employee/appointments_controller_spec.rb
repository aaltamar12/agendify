# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Api::V1::Employee::AppointmentsController, type: :request do
  let(:user) { create(:user, role: :employee) }
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business, user: user) }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:headers) { auth_headers(user) }

  before { employee } # ensure employee is created

  describe "GET /api/v1/employee/appointments" do
    let!(:appointment) do
      create(:appointment, business: business, employee: employee, service: service, customer: customer)
    end

    it "returns employee appointments" do
      get "/api/v1/employee/appointments", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(1)
    end

    it "filters by date" do
      get "/api/v1/employee/appointments", params: { date: Date.tomorrow.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(1)
    end

    it "filters by status" do
      get "/api/v1/employee/appointments", params: { status: "pending_payment" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].length).to eq(1)
    end

    it "returns empty for non-matching filter" do
      get "/api/v1/employee/appointments", params: { date: Date.yesterday.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_empty
    end
  end

  describe "POST /api/v1/employee/checkin_by_code" do
    let!(:appointment) do
      create(:appointment, :confirmed, business: business, employee: employee, service: service, customer: customer)
    end

    it "checks in successfully" do
      checkin_data = {
        appointment: appointment,
        customer_name: customer.name,
        last_visit: nil,
        visit_count: 1
      }
      result = OpenStruct.new(success?: true, data: checkin_data)
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/checkin_by_code", params: { ticket_code: appointment.ticket_code }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["customer_name"]).to eq(customer.name)
    end

    it "returns conflict when requires confirmation" do
      result = OpenStruct.new(
        success?: false,
        error: "Different employee assigned",
        data: { requires_confirmation: true, assigned_employee: "John" }
      )
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/checkin_by_code", params: { ticket_code: appointment.ticket_code }, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["requires_confirmation"]).to be true
    end

    it "returns error on failure" do
      result = OpenStruct.new(success?: false, error: "Already checked in", data: nil)
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/checkin_by_code", params: { ticket_code: appointment.ticket_code }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Already checked in")
    end
  end

  describe "POST /api/v1/employee/appointments/:id/checkin" do
    let!(:appointment) do
      create(:appointment, :confirmed, business: business, employee: employee, service: service, customer: customer)
    end

    it "checks in successfully" do
      checkin_data = {
        appointment: appointment,
        customer_name: customer.name,
        last_visit: nil,
        visit_count: 1
      }
      result = OpenStruct.new(success?: true, data: checkin_data)
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/appointments/#{appointment.id}/checkin", headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "returns conflict when requires confirmation" do
      result = OpenStruct.new(
        success?: false,
        error: "Different employee assigned",
        data: { requires_confirmation: true, assigned_employee: "John" }
      )
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/appointments/#{appointment.id}/checkin", headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["requires_confirmation"]).to be true
    end

    it "returns error on failure" do
      result = OpenStruct.new(success?: false, error: "Cannot check in", data: nil)
      allow(Appointments::CheckinService).to receive(:call).and_return(result)

      post "/api/v1/employee/appointments/#{appointment.id}/checkin", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
