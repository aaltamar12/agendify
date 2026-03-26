# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::NotificationConfig", type: :request do
  describe "GET /api/v1/notification_config" do
    it "returns notification event configurations" do
      get "/api/v1/notification_config"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns serialized config with expected keys" do
      create(:notification_event_config,
        event_key: "new_booking",
        title: "New Booking",
        body_template: "A new booking was made",
        browser_notification: true,
        sound_enabled: true,
        in_app_notification: true,
        active: true)

      get "/api/v1/notification_config"
      expect(response).to have_http_status(:ok)
      config = response.parsed_body["data"].first
      expect(config).to include("event_key", "title", "body_template", "browser_notification", "sound_enabled")
    end
  end
end
