# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::RequestLogs", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/request_logs" do
    it "returns success" do
      create(:request_log)
      get "/admin/request_logs"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/request_logs/:id" do
    it "returns success" do
      log = create(:request_log)
      get "/admin/request_logs/#{log.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
