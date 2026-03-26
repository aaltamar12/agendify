# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CashRegisterCloses", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/cash_register_closes" do
    it "returns success" do
      create(:cash_register_close)
      get "/admin/cash_register_closes"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/cash_register_closes/:id" do
    it "returns success" do
      close = create(:cash_register_close)
      get "/admin/cash_register_closes/#{close.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
