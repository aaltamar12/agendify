# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SiteConfigs", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/site_configs" do
    it "returns success" do
      create(:site_config)
      get "/admin/site_configs"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/site_configs/:id" do
    it "returns success" do
      config = create(:site_config)
      get "/admin/site_configs/#{config.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/site_configs/:id/edit" do
    it "returns success" do
      config = create(:site_config)
      get "/admin/site_configs/#{config.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/site_configs/:id" do
    it "updates the value" do
      config = create(:site_config, value: "old_value")
      patch "/admin/site_configs/#{config.id}", params: { site_config: { value: "new_value" } }
      expect(config.reload.value).to eq("new_value")
    end
  end
end
