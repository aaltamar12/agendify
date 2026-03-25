# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::AdBanners", type: :request do
  describe "GET /api/v1/public/ad_banners" do
    it "returns a banner for the given placement" do
      get "/api/v1/public/ad_banners", params: { placement: "booking_summary" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/public/ad_banners/:id/impression" do
    it "tracks an impression" do
      banner = AdBanner.create!(
        name: "Test Banner",
        placement: "booking_summary",
        image_url: "https://example.com/img.jpg",
        link_url: "https://example.com",
        active: true,
        priority: 1,
        start_date: Date.current,
        end_date: Date.current + 30
      )
      post "/api/v1/public/ad_banners/#{banner.id}/impression"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["tracked"]).to be true
    end
  end

  describe "POST /api/v1/public/ad_banners/:id/click" do
    it "tracks a click" do
      banner = AdBanner.create!(
        name: "Test Banner",
        placement: "booking_summary",
        image_url: "https://example.com/img.jpg",
        link_url: "https://example.com",
        active: true,
        priority: 1,
        start_date: Date.current,
        end_date: Date.current + 30
      )
      post "/api/v1/public/ad_banners/#{banner.id}/click"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["tracked"]).to be true
    end
  end
end
