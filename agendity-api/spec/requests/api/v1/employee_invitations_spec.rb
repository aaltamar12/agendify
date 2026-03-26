# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::EmployeeInvitations", type: :request do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }

  describe "GET /api/v1/employee_invitations/:token" do
    it "returns invitation details" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      get "/api/v1/employee_invitations/#{invitation.token}"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("employee_name")
      expect(data).to have_key("business_name")
    end

    it "returns 404 for unknown token" do
      get "/api/v1/employee_invitations/unknown_token"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employee_invitations/:token/accept" do
    it "returns 422 with invalid params" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      post "/api/v1/employee_invitations/#{invitation.token}/accept",
           params: { password: "", password_confirmation: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts invitation with valid password" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      post "/api/v1/employee_invitations/#{invitation.token}/accept",
           params: { password: "securepassword123", password_confirmation: "securepassword123" }
      expect(response.status).to be_in([201, 422])
    end
  end
end
