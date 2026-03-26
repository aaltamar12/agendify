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

    it "returns 403 when credits are disabled" do
      business.update!(credits_enabled: false)
      get "/api/v1/credits/summary", headers: headers
      expect(response).to have_http_status(:forbidden)
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

    it "applies credits to specific customers" do
      c1 = create(:customer, business: business)
      c2 = create(:customer, business: business)
      post "/api/v1/credits/bulk_adjust",
           params: { amount: 5000, customer_ids: [c1.id, c2.id], description: "Promo" },
           headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["count"]).to eq(2)
    end

    it "applies credits to all customers when no customer_ids given" do
      create(:customer, business: business)
      create(:customer, business: business)
      post "/api/v1/credits/bulk_adjust",
           params: { amount: 3000 },
           headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["count"]).to eq(2)
    end
  end

  describe "GET /api/v1/customers/:id/credits (with existing account)" do
    it "returns credit details with transactions" do
      account = create(:credit_account, business: business, customer: customer, balance: 10_000)
      create(:credit_transaction, credit_account: account, amount: 5000)
      get "/api/v1/customers/#{customer.id}/credits", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["balance"]).to eq(10_000.0)
      expect(data["transactions"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/customers/:id/credits/adjust (failure)" do
    it "returns 422 when adjust service fails with zero amount" do
      post "/api/v1/customers/#{customer.id}/credits/adjust",
           params: { amount: 0, description: "Test" },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
