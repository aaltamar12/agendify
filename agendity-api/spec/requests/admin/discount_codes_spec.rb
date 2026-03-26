# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::DiscountCodes", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business) }
  let!(:discount_code) { create(:discount_code, business: business) }

  before { admin_login(admin) }

  describe "GET /admin/discount_codes" do
    it "returns success" do
      get admin_discount_codes_path
      expect(response).to have_http_status(:success)
    end

    it "displays the discount code" do
      get admin_discount_codes_path
      expect(response.body).to include(discount_code.code)
    end
  end

  describe "GET /admin/discount_codes/:id" do
    it "returns success" do
      get admin_discount_code_path(discount_code)
      expect(response).to have_http_status(:success)
    end

    it "displays discount code details" do
      get admin_discount_code_path(discount_code)
      expect(response.body).to include(discount_code.code)
    end
  end

  describe "GET /admin/discount_codes/new" do
    it "returns success" do
      get new_admin_discount_code_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/discount_codes/:id/edit" do
    it "returns success" do
      get edit_admin_discount_code_path(discount_code)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/discount_codes" do
    it "creates a new discount code" do
      expect {
        post admin_discount_codes_path, params: {
          discount_code: {
            business_id: business.id,
            code: "NEWDISC20",
            discount_type: "percentage",
            discount_value: 20,
            active: true
          }
        }
      }.to change(DiscountCode, :count).by(1)
    end
  end

  describe "PATCH /admin/discount_codes/:id" do
    it "updates the discount code" do
      patch admin_discount_code_path(discount_code), params: {
        discount_code: { discount_value: 25 }
      }
      expect(discount_code.reload.discount_value).to eq(25)
    end
  end
end
