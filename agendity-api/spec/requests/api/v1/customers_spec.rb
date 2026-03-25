# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/customers" do
    it "returns customers for the business" do
      create(:customer, business: business)
      get "/api/v1/customers", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "searches by name" do
      create(:customer, business: business, name: "Carlos Pérez")
      get "/api/v1/customers", params: { search: "Carlos" }, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without token" do
      get "/api/v1/customers"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/customers/:id" do
    it "returns a specific customer" do
      customer = create(:customer, business: business)
      get "/api/v1/customers/#{customer.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(customer.id)
    end

    it "returns 404 for another business customer" do
      other_customer = create(:customer)
      get "/api/v1/customers/#{other_customer.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
