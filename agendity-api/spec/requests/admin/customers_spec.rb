# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Customers", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/customers" do
    it "returns success" do
      create(:customer)
      get "/admin/customers"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/customers/:id" do
    it "returns success" do
      customer = create(:customer)
      get "/admin/customers/#{customer.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
