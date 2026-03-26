# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::AdminNotifications", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/admin_notifications" do
    it "returns success" do
      create(:admin_notification)
      get "/admin/admin_notifications"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/admin_notifications/:id" do
    it "returns success" do
      notification = create(:admin_notification)
      get "/admin/admin_notifications/#{notification.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /admin/admin_notifications/:id/mark_read" do
    it "marks notification as read" do
      notification = create(:admin_notification, read: false)
      put "/admin/admin_notifications/#{notification.id}/mark_read"
      expect(response).to redirect_to(admin_admin_notifications_path)
      expect(notification.reload.read).to be true
    end
  end

  describe "PUT /admin/admin_notifications/mark_all_read" do
    it "marks all notifications as read" do
      create_list(:admin_notification, 2, read: false)
      put "/admin/admin_notifications/mark_all_read"
      expect(response).to redirect_to(admin_admin_notifications_path)
      expect(AdminNotification.where(read: false).count).to eq(0)
    end
  end
end
