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
  end
end
