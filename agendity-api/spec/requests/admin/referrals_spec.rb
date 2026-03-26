# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Referrals", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/referrals" do
    it "returns success" do
      create(:referral)
      get "/admin/referrals"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/referrals/:id" do
    it "returns success" do
      referral = create(:referral)
      get "/admin/referrals/#{referral.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
