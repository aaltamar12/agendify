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

  describe "POST /api/v1/customers/:id/send_birthday_greeting" do
    let(:customer) { create(:customer, business: business) }

    context "with Plan Inteligente (ai_features)" do
      let(:plan) { create(:plan, ai_features: true) }

      before do
        create(:subscription, business: business, plan: plan, status: :active)
      end

      it "sends birthday greeting and returns success" do
        allow(Notifications::MultiChannelService).to receive(:call).and_return(double(success?: true))

        post "/api/v1/customers/#{customer.id}/send_birthday_greeting", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["message"]).to eq("Saludo de cumpleaños enviado")
        expect(Notifications::MultiChannelService).to have_received(:call).with(
          hash_including(
            business: business,
            recipient: customer,
            template: :birthday_greeting_manual
          )
        )
      end
    end

    context "without Plan Inteligente" do
      let(:plan) { create(:plan, ai_features: false) }

      before do
        create(:subscription, business: business, plan: plan, status: :active)
      end

      it "returns forbidden" do
        post "/api/v1/customers/#{customer.id}/send_birthday_greeting", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("Inteligente")
      end
    end

    context "without any subscription (trial)" do
      it "sends birthday greeting during trial (all features available)" do
        allow(Notifications::MultiChannelService).to receive(:call).and_return(double(success?: true))

        post "/api/v1/customers/#{customer.id}/send_birthday_greeting", headers: headers

        # Trial grants all features via has_feature? — no plan = trial = all features
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns 404 for another business customer" do
      other_customer = create(:customer)
      post "/api/v1/customers/#{other_customer.id}/send_birthday_greeting", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
