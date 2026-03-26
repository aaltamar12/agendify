# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CreditAccounts", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/credit_accounts" do
    it "returns success" do
      create(:credit_account)
      get "/admin/credit_accounts"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/credit_accounts/:id" do
    it "returns success" do
      account = create(:credit_account)
      get "/admin/credit_accounts/#{account.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
