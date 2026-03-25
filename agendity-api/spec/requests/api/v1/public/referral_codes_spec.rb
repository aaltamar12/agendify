# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::ReferralCodes", type: :request do
  describe "GET /api/v1/public/referral_codes/:code/validate" do
    it "validates an active referral code" do
      referral = create(:referral_code, code: "TESTREF", status: :active)
      get "/api/v1/public/referral_codes/TESTREF/validate"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["valid"]).to be true
      expect(data["referrer_name"]).to eq(referral.referrer_name)
    end

    it "returns valid: false for unknown code" do
      get "/api/v1/public/referral_codes/UNKNOWN/validate"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["valid"]).to be false
    end
  end
end
