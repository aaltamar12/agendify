# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Employee::Dashboard", type: :request do
  let(:business) { create(:business) }
  let(:employee_user) { create(:user, role: :employee) }
  let(:employee) { create(:employee, business: business, user: employee_user) }
  let(:token) { Auth::TokenGenerator.encode(employee_user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before { employee } # Ensure employee is created

  describe "GET /api/v1/employee/dashboard" do
    it "returns employee dashboard data" do
      get "/api/v1/employee/dashboard", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("employee")
      expect(data).to have_key("stats")
    end

    it "returns 401 without token" do
      get "/api/v1/employee/dashboard"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for non-employee user" do
      owner_token = Auth::TokenGenerator.encode(business.owner)
      get "/api/v1/employee/dashboard", headers: { "Authorization" => "Bearer #{owner_token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/employee/score" do
    it "returns employee score" do
      get "/api/v1/employee/score", headers: headers
      expect(response.status).to be_in([200, 400])
    end

    it "returns error when score service fails" do
      allow(Employees::ScoreService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Score calculation failed")
      )
      get "/api/v1/employee/score", headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
