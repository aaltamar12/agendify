# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::NotificationEventConfigs", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/notification_event_configs" do
    it "returns success" do
      create(:notification_event_config)
      get "/admin/notification_event_configs"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/notification_event_configs/:id" do
    it "returns success" do
      config = create(:notification_event_config)
      get "/admin/notification_event_configs/#{config.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/notification_event_configs/new" do
    it "returns success" do
      get "/admin/notification_event_configs/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/notification_event_configs" do
    it "creates a config" do
      expect {
        post "/admin/notification_event_configs", params: {
          notification_event_config: {
            event_key: "test_new_event",
            title: "New Event",
            body_template: "Hello {{name}}",
            browser_notification: true,
            sound_enabled: true,
            in_app_notification: true,
            active: true
          }
        }
      }.to change(NotificationEventConfig, :count).by(1)
    end
  end
end
