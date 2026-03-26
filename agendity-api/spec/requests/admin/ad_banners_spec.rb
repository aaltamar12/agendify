# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::AdBanners", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/ad_banners" do
    it "returns success" do
      create(:ad_banner)
      get "/admin/ad_banners"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/ad_banners/:id" do
    it "returns success" do
      banner = create(:ad_banner)
      get "/admin/ad_banners/#{banner.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/ad_banners/new" do
    it "returns success" do
      get "/admin/ad_banners/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/ad_banners" do
    it "creates a banner" do
      expect {
        post "/admin/ad_banners", params: {
          ad_banner: { name: "New Banner", placement: "booking_summary", active: true, priority: 1 }
        }
      }.to change(AdBanner, :count).by(1)
    end
  end
end
