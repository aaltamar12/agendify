# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SendNotification", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/send_notification" do
    it "returns success" do
      get "/admin/send_notification"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/send_notification/deliver" do
    let!(:business) { create(:business) }

    it "sends notifications to selected businesses" do
      expect {
        post "/admin/send_notification/deliver", params: {
          target: "selected",
          business_ids: [business.id],
          notification_type: "reminder",
          custom_title: "Test Title",
          custom_body: "Test Body"
        }
      }.to change(Notification, :count).by(1)
      expect(response).to redirect_to(admin_send_notification_path)
    end

    it "redirects with alert when no businesses selected" do
      post "/admin/send_notification/deliver", params: {
        target: "selected",
        business_ids: [],
        notification_type: "reminder"
      }
      expect(response).to redirect_to(admin_send_notification_path)
      expect(flash[:alert]).to be_present
    end
  end
end
