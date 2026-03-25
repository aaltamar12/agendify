# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::BusinessHours", type: :request do
  let(:business) { create(:business, :with_hours) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/business_hours" do
    it "returns business hours" do
      get "/api/v1/business_hours", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/business_hours"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/business_hours" do
    it "updates business hours" do
      params = {
        business_hours: [
          { day_of_week: 1, open_time: "09:00", close_time: "17:00", closed: false }
        ]
      }
      patch "/api/v1/business_hours", params: params, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
