# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::NotificationConfig", type: :request do
  describe "GET /api/v1/notification_config" do
    it "returns notification event configurations" do
      get "/api/v1/notification_config"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end
end
