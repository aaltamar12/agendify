# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Notifications", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/notifications" do
    it "returns notifications for the business" do
      create(:notification, business: business)
      get "/api/v1/notifications", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/notifications"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/notifications/:id/mark_read" do
    it "marks a notification as read" do
      notification = create(:notification, business: business, read: false)
      post "/api/v1/notifications/#{notification.id}/mark_read", headers: headers
      expect(response).to have_http_status(:ok)
      expect(notification.reload.read).to be true
    end
  end

  describe "POST /api/v1/notifications/mark_all_read" do
    it "marks all notifications as read" do
      create(:notification, business: business, read: false)
      post "/api/v1/notifications/mark_all_read", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/notifications/unread_count" do
    it "returns unread count" do
      create(:notification, business: business, read: false)
      get "/api/v1/notifications/unread_count", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["unread_count"]).to eq(1)
    end
  end
end
