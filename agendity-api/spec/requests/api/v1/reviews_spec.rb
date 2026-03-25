# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reviews", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/reviews" do
    it "returns reviews for the business" do
      customer = create(:customer, business: business)
      create(:review, business: business, customer: customer)
      get "/api/v1/reviews", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/reviews"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
