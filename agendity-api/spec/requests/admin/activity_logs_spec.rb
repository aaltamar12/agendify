# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ActivityLogs", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:activity_log) { create(:activity_log, action: "booking_created") }

  before { admin_login(admin) }

  describe "GET /admin/activity_logs" do
    it "returns success" do
      get admin_activity_logs_path
      expect(response).to have_http_status(:success)
    end

    it "displays activity logs" do
      get admin_activity_logs_path
      expect(response.body).to include(activity_log.business.name)
    end

    context "with default scope (reservations)" do
      let!(:booking_log) { create(:activity_log, action: "booking_created") }
      let!(:other_log) { create(:activity_log, action: "payment_received") }

      it "shows booking logs by default" do
        get admin_activity_logs_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /admin/activity_logs/:id" do
    it "returns success" do
      get admin_activity_log_path(activity_log)
      expect(response).to have_http_status(:success)
    end

    it "displays log details" do
      get admin_activity_log_path(activity_log)
      expect(response.body).to include(activity_log.action)
    end

    context "with resource lifecycle" do
      let!(:activity_log) do
        create(:activity_log, action: "booking_created", resource_type: "Appointment", resource_id: 999)
      end

      it "displays lifecycle panel" do
        get admin_activity_log_path(activity_log)
        expect(response.body).to include("Ciclo de vida completo")
      end
    end
  end
end
