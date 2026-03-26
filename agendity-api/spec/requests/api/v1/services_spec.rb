# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Services", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/services" do
    it "returns services for the business" do
      create(:service, business: business)
      get "/api/v1/services", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/services"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/services" do
    it "creates a service" do
      params = { service: { name: "Corte", price: 25000, duration_minutes: 30 } }
      post "/api/v1/services", params: params, headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["name"]).to eq("Corte")
    end

    it "returns 422 with invalid params" do
      post "/api/v1/services", params: { service: { name: "" } }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/services/:id" do
    it "updates a service" do
      service = create(:service, business: business)
      patch "/api/v1/services/#{service.id}", params: { service: { name: "Updated" } }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Updated")
    end

    it "returns 404 for another business service" do
      other_service = create(:service)
      patch "/api/v1/services/#{other_service.id}", params: { service: { name: "X" } }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/services/:id" do
    it "soft-deletes a service" do
      service = create(:service, business: business)
      delete "/api/v1/services/#{service.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(service.reload.active).to be false
    end

    it "returns 404 for another business service" do
      other_service = create(:service)
      delete "/api/v1/services/#{other_service.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/services/:id" do
    it "returns a specific service" do
      service = create(:service, business: business)
      get "/api/v1/services/#{service.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(service.id)
    end

    it "returns 404 for another business service" do
      other_service = create(:service)
      get "/api/v1/services/#{other_service.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/services/categories" do
    it "returns distinct categories" do
      create(:service, business: business, category: "Cortes")
      create(:service, business: business, category: "Barba")
      create(:service, business: business, category: "Cortes") # duplicate
      create(:service, business: business, category: nil)

      get "/api/v1/services/categories", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to contain_exactly("Barba", "Cortes")
    end

    it "returns empty array when no categories" do
      get "/api/v1/services/categories", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end
  end

  describe "PATCH /api/v1/services/rename_category" do
    it "renames a category" do
      create(:service, business: business, category: "Cortes")
      create(:service, business: business, category: "Cortes")

      patch "/api/v1/services/rename_category",
            params: { old_name: "Cortes", new_name: "Cortes Premium" },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["updated"]).to eq(2)
      expect(response.parsed_body["data"]["new_name"]).to eq("Cortes Premium")
    end

    it "returns 422 when old_name is missing" do
      patch "/api/v1/services/rename_category",
            params: { new_name: "Cortes Premium" },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when new_name is missing" do
      patch "/api/v1/services/rename_category",
            params: { old_name: "Cortes" },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/services/delete_category" do
    it "removes category from services" do
      create(:service, business: business, category: "Extras")
      create(:service, business: business, category: "Extras")

      delete "/api/v1/services/delete_category",
             params: { name: "Extras" },
             headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["updated"]).to eq(2)
    end

    it "returns 422 when name is missing" do
      delete "/api/v1/services/delete_category", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/services (plan limit)" do
    it "returns 403 when plan limit reached" do
      plan = create(:plan, max_services: 1)
      create(:subscription, business: business, plan: plan, status: :active)
      create(:service, business: business, active: true)

      params = { service: { name: "Extra Service", price: 20000, duration_minutes: 30 } }
      post "/api/v1/services", params: params, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
