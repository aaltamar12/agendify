# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/employees" do
    it "returns employees for the business" do
      create(:employee, business: business)
      get "/api/v1/employees", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/employees"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/employees" do
    it "creates an employee" do
      params = { employee: { name: "Juan", phone: "3001234567" } }
      post "/api/v1/employees", params: params, headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["name"]).to eq("Juan")
    end

    it "returns 422 with invalid params" do
      post "/api/v1/employees", params: { employee: { name: "" } }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    it "updates an employee" do
      employee = create(:employee, business: business)
      patch "/api/v1/employees/#{employee.id}", params: { employee: { name: "Updated" } }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Updated")
    end

    it "returns 404 for another business employee" do
      other_employee = create(:employee)
      patch "/api/v1/employees/#{other_employee.id}", params: { employee: { name: "X" } }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "soft-deletes an employee" do
      employee = create(:employee, business: business)
      delete "/api/v1/employees/#{employee.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(employee.reload.active).to be false
    end
  end

  describe "POST /api/v1/employees/:id/upload_avatar" do
    it "returns 422 without file" do
      employee = create(:employee, business: business)
      post "/api/v1/employees/#{employee.id}/upload_avatar", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/employees/:id/invite" do
    it "returns 422 without email" do
      employee = create(:employee, business: business, email: nil)
      post "/api/v1/employees/#{employee.id}/invite", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/employees/:id/adjust_balance" do
    it "returns 403 without intelligent plan" do
      plan = create(:plan, ai_features: false)
      create(:subscription, business: business, plan: plan)
      employee = create(:employee, business: business)
      post "/api/v1/employees/#{employee.id}/adjust_balance",
           params: { amount: 5000, reason: "correction" },
           headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/employees/:id/balance_history" do
    it "returns 403 without intelligent plan" do
      plan = create(:plan, ai_features: false)
      create(:subscription, business: business, plan: plan)
      employee = create(:employee, business: business)
      get "/api/v1/employees/#{employee.id}/balance_history", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
