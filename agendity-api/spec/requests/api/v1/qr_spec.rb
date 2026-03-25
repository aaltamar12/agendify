# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Qr", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/v1/qr/generate" do
    it "returns the booking URL" do
      post "/api/v1/qr/generate", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["url"]).to include(business.slug)
      expect(data["slug"]).to eq(business.slug)
    end

    it "returns 401 without token" do
      post "/api/v1/qr/generate"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
