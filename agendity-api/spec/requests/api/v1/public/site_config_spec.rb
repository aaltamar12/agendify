# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::SiteConfig", type: :request do
  before do
    allow(SiteConfig).to receive(:get).and_return("test_value")
  end

  describe "GET /api/v1/public/site_config" do
    it "returns site configuration" do
      get "/api/v1/public/site_config"
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to have_key("support_email")
      expect(data).to have_key("payment_nequi")
      expect(data).to have_key("company_name")
    end
  end
end
