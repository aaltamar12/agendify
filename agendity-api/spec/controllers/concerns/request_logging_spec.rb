# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestLogging, type: :request do
  let(:user) { create(:user) }
  let(:business) { create(:business, owner: user) }
  let(:headers) { auth_headers(user) }

  before { business }

  describe "logging requests" do
    it "creates a request log for successful requests" do
      expect {
        get "/api/v1/appointments", headers: headers
      }.to change(RequestLog, :count).by(1)

      log = RequestLog.last
      expect(log.method).to eq("GET")
      expect(log.path).to eq("/api/v1/appointments")
      expect(log.status_code).to eq(200)
      expect(log.duration_ms).to be_present
      expect(log.request_id).to be_present
      expect(log.business_id).to eq(business.id)
    end

    it "logs request params without sensitive data" do
      get "/api/v1/appointments", params: { page: 1 }, headers: headers

      log = RequestLog.last
      expect(log.request_params).to include("page" => "1")
      expect(log.request_params.keys).not_to include("password", "token", "refresh_token")
    end

    it "logs errors when exceptions occur" do
      get "/api/v1/services/999999", headers: headers

      log = RequestLog.last
      # RecordNotFound is caught by around_action first (sets @_request_error),
      # then re-raised and handled by rescue_from. The log captures the error state.
      expect(log.error_message).to be_present
      expect(log.controller_action).to include("services")
    end

    it "handles request log save failures gracefully" do
      allow(RequestLog).to receive(:create!).and_raise(StandardError.new("DB error"))

      expect {
        get "/api/v1/appointments", headers: headers
      }.not_to raise_error

      expect(response).to have_http_status(:ok)
    end
  end

  describe "resolve_business_id" do
    it "resolves business from authenticated user" do
      get "/api/v1/appointments", headers: headers

      log = RequestLog.last
      expect(log.business_id).to eq(business.id)
    end

    it "resolves nil for public endpoints" do
      biz = create(:business, status: :active)

      get "/api/v1/public/#{biz.slug}"

      log = RequestLog.last
      # Public endpoints have no auth so business_id is nil
      expect(log.business_id).to be_nil
    end
  end

  describe "detect_resource" do
    it "detects appointment resource" do
      service = create(:service, business: business)
      employee = create(:employee, business: business)
      customer = create(:customer, business: business)
      appointment = create(:appointment, business: business, service: service, employee: employee, customer: customer)

      get "/api/v1/appointments/#{appointment.id}", headers: headers

      log = RequestLog.last
      expect(log.resource_type).to eq("Appointment")
      expect(log.resource_id).to eq(appointment.id)
    end
  end

  describe "filtered_request_params" do
    it "filters sensitive params" do
      post "/api/v1/auth/login", params: { email: "test@test.com", password: "secret123" }

      log = RequestLog.last
      expect(log.request_params.keys).not_to include("password")
      expect(log.request_params).to include("email" => "test@test.com")
    end
  end
end
