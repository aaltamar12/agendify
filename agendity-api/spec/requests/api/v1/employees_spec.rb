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

    it "returns balance history timeline with intelligent plan" do
      # Trial = all features enabled (no plan/subscription needed)
      employee = create(:employee, business: business)
      create(:employee_balance_adjustment,
             business: business,
             employee: employee,
             performed_by_user: user,
             amount: 5000,
             balance_before: 0,
             balance_after: 5000,
             reason: "correction")

      get "/api/v1/employees/#{employee.id}/balance_history", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["employee_id"]).to eq(employee.id)
      expect(data["employee_name"]).to eq(employee.name)
      expect(data).to have_key("current_balance")
      expect(data["timeline"]).to be_an(Array)
      expect(data["timeline"].first["type"]).to eq("adjustment")
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns an employee with services" do
      employee = create(:employee, business: business)
      get "/api/v1/employees/#{employee.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(employee.id)
    end

    it "returns 404 for another business employee" do
      other_employee = create(:employee)
      get "/api/v1/employees/#{other_employee.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employees (plan limit)" do
    it "returns 403 when employee limit is reached" do
      plan = create(:plan, max_employees: 1)
      create(:subscription, business: business, plan: plan)
      create(:employee, business: business)

      post "/api/v1/employees",
           params: { employee: { name: "Extra", phone: "3009999999" } },
           headers: headers
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("límite")
    end
  end

  describe "POST /api/v1/employees with service_ids" do
    it "creates employee and assigns services" do
      svc = create(:service, business: business)
      post "/api/v1/employees",
           params: { employee: { name: "Ana", phone: "3001111111", service_ids: [svc.id] } },
           headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/employees/:id with service_ids" do
    it "updates employee and reassigns services" do
      employee = create(:employee, business: business)
      svc = create(:service, business: business)
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { service_ids: [svc.id] } },
            headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 422 with invalid params" do
      employee = create(:employee, business: business)
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { name: "" } },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/employees/:id/upload_avatar with file" do
    it "attaches avatar to the employee record" do
      employee = create(:employee, business: business)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png")

      # Set default_url_options so the serializer can generate URLs
      Rails.application.routes.default_url_options[:host] = "localhost:3000"

      post "/api/v1/employees/#{employee.id}/upload_avatar",
           params: { avatar: file },
           headers: headers
      expect(response).to have_http_status(:ok)
      expect(employee.reload.avatar).to be_attached
    end
  end

  describe "POST /api/v1/employees/:id/invite with email" do
    it "sends invitation successfully" do
      employee = create(:employee, business: business, email: "emp@test.com")
      post "/api/v1/employees/#{employee.id}/invite",
           params: { email: "emp@test.com", send_email: false },
           headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["message"]).to include("Invitacion")
      expect(data).to have_key("register_url")
    end

    it "returns 422 when invite service fails" do
      employee = create(:employee, business: business, email: "emp@test.com")
      # Link a user to make the invite fail
      employee.update_column(:user_id, user.id)
      post "/api/v1/employees/#{employee.id}/invite",
           params: { email: "emp@test.com" },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/employees/:id/adjust_balance with intelligent plan" do
    it "adjusts balance successfully" do
      # Trial = all features
      employee = create(:employee, business: business)
      post "/api/v1/employees/#{employee.id}/adjust_balance",
           params: { amount: 5000, reason: "correction", notes: "test" },
           headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 422 when service fails (zero amount)" do
      employee = create(:employee, business: business)
      post "/api/v1/employees/#{employee.id}/adjust_balance",
           params: { amount: 0, reason: "correction" },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
