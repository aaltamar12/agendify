# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "Admin::SubscriptionPaymentOrders", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:order) { create(:subscription_payment_order) }

  before { admin_login(admin) }

  describe "GET /admin/subscription_payment_orders" do
    it "returns success" do
      get admin_subscription_payment_orders_path
      expect(response).to have_http_status(:success)
    end

    it "displays the payment order" do
      get admin_subscription_payment_orders_path
      expect(response.body).to include(order.business.name)
    end
  end

  describe "GET /admin/subscription_payment_orders/:id" do
    it "returns success" do
      get admin_subscription_payment_order_path(order)
      expect(response).to have_http_status(:success)
    end

    it "displays order details" do
      get admin_subscription_payment_order_path(order)
      expect(response.body).to include(order.business.name)
    end
  end

  describe "PUT /admin/subscription_payment_orders/:id/mark_as_paid" do
    it "marks a pending order as paid" do
      put mark_as_paid_admin_subscription_payment_order_path(order)
      expect(order.reload.status).to eq("paid")
      expect(response).to redirect_to(admin_subscription_payment_order_path(order))
    end
  end

  describe "PUT /admin/subscription_payment_orders/:id/reject_proof" do
    let!(:order) { create(:subscription_payment_order, status: "proof_submitted") }

    it "rejects the proof" do
      put reject_proof_admin_subscription_payment_order_path(order)
      expect(order.reload.status).to eq("rejected")
      expect(order.reviewed_by).to eq(admin.email)
      expect(response).to redirect_to(admin_subscription_payment_order_path(order))
    end
  end

  describe "PUT /admin/subscription_payment_orders/:id/approve_proof" do
    let!(:order) { create(:subscription_payment_order, status: "proof_submitted") }

    before do
      allow(Subscriptions::ApprovePaymentService).to receive(:call).and_return(
        OpenStruct.new(success?: true)
      )
    end

    it "approves the proof and activates subscription" do
      put approve_proof_admin_subscription_payment_order_path(order)
      expect(response).to redirect_to(admin_subscription_payment_order_path(order))
      expect(flash[:notice]).to include("aprobado")
    end

    context "when service fails" do
      before do
        allow(Subscriptions::ApprovePaymentService).to receive(:call).and_return(
          OpenStruct.new(success?: false, error: "Plan not found")
        )
      end

      it "redirects with error" do
        put approve_proof_admin_subscription_payment_order_path(order)
        expect(response).to redirect_to(admin_subscription_payment_order_path(order))
        expect(flash[:alert]).to include("Error")
      end
    end
  end
end
