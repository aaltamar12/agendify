# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Subscriptions", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/subscriptions" do
    it "returns success" do
      create(:subscription)
      get "/admin/subscriptions"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/subscriptions/:id" do
    it "returns success" do
      subscription = create(:subscription)
      get "/admin/subscriptions/#{subscription.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/subscriptions/:id/edit" do
    it "returns success" do
      subscription = create(:subscription)
      get "/admin/subscriptions/#{subscription.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end
end
