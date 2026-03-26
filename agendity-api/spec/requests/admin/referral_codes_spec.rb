# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ReferralCodes", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:referral_code) { create(:referral_code) }

  before { admin_login(admin) }

  describe "GET /admin/referral_codes" do
    it "returns success" do
      get admin_referral_codes_path
      expect(response).to have_http_status(:success)
    end

    it "displays the referral code" do
      get admin_referral_codes_path
      expect(response.body).to include(referral_code.code)
    end
  end

  describe "GET /admin/referral_codes/:id" do
    it "returns success" do
      get admin_referral_code_path(referral_code)
      expect(response).to have_http_status(:success)
    end

    it "displays referral code details" do
      get admin_referral_code_path(referral_code)
      expect(response.body).to include(referral_code.referrer_name)
    end
  end

  describe "GET /admin/referral_codes/new" do
    it "returns success" do
      get new_admin_referral_code_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/referral_codes/:id/edit" do
    it "returns success" do
      get edit_admin_referral_code_path(referral_code)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/referral_codes" do
    it "creates a new referral code" do
      expect {
        post admin_referral_codes_path, params: {
          referral_code: {
            code: "NEWREF123",
            referrer_name: "Test Referrer",
            referrer_email: "referrer@example.com",
            commission_percentage: 15.0,
            status: "active"
          }
        }
      }.to change(ReferralCode, :count).by(1)
    end
  end

  describe "PATCH /admin/referral_codes/:id" do
    it "updates the referral code" do
      patch admin_referral_code_path(referral_code), params: {
        referral_code: { referrer_name: "Updated Name" }
      }
      expect(referral_code.reload.referrer_name).to eq("Updated Name")
    end
  end
end
