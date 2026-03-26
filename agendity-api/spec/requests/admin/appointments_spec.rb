# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Appointments", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/appointments" do
    it "returns success" do
      create(:appointment)
      get "/admin/appointments"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/appointments/:id" do
    it "returns success" do
      appointment = create(:appointment)
      get "/admin/appointments/#{appointment.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
