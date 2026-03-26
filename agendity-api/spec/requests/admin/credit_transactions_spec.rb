# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CreditTransactions", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/credit_transactions" do
    it "returns success" do
      create(:credit_transaction)
      get "/admin/credit_transactions"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/credit_transactions/:id" do
    it "returns success" do
      transaction = create(:credit_transaction)
      get "/admin/credit_transactions/#{transaction.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
