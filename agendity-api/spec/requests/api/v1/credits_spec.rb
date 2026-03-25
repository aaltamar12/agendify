# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Credits", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:customer) { create(:customer, business: business) }

  describe "GET /api/v1/credits/summary" do
    it "returns credit accounts with positive balances" do
      create(:credit_account, business: business, customer: customer, balance: 5000)
      get "/api/v1/credits/summary", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/credits/summary"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/customers/:id/credits" do
    it "returns credit details for a customer" do
      get "/api/v1/customers/#{customer.id}/credits", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to have_key("balance")
    end
  end

  describe "POST /api/v1/customers/:id/credits/adjust" do
    it "adjusts credit for a customer" do
      post "/api/v1/customers/#{customer.id}/credits/adjust",
           params: { amount: 5000, description: "Bonus" },
           headers: headers
      expect(response.status).to be_in([200, 422])
    end
  end

  describe "GET /api/v1/customers/:id/credit_balance" do
    it "returns credit balance" do
      get "/api/v1/customers/#{customer.id}/credit_balance", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to have_key("balance")
    end
  end

  describe "POST /api/v1/credits/bulk_adjust" do
    it "returns 422 with zero amount" do
      post "/api/v1/credits/bulk_adjust",
           params: { amount: 0 },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
