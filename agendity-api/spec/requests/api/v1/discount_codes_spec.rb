# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::DiscountCodes", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/discount_codes" do
    it "returns discount codes" do
      create(:discount_code, business: business)
      get "/api/v1/discount_codes", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/discount_codes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/discount_codes" do
    it "creates a discount code" do
      params = {
        discount_code: {
          code: "SUMMER20",
          discount_type: "percentage",
          discount_value: 20,
          active: true
        }
      }
      post "/api/v1/discount_codes", params: params, headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["code"]).to eq("SUMMER20")
    end

    it "returns 422 with invalid params" do
      post "/api/v1/discount_codes", params: { discount_code: { code: "" } }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/discount_codes/:id" do
    it "deletes a discount code" do
      code = create(:discount_code, business: business)
      delete "/api/v1/discount_codes/#{code.id}", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
