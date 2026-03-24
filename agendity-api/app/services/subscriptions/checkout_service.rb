# frozen_string_literal: true

module Subscriptions
  # Creates a subscription payment order with proof of payment (P2P transfer).
  # The business selects a plan, transfers money, uploads proof, and waits for admin approval.
  class CheckoutService < BaseService
    def initialize(business:, plan_id:, proof:)
      @business = business
      @plan_id  = plan_id
      @proof    = proof
    end

    def call
      plan = Plan.find_by(id: @plan_id)
      return failure("Plan not found", code: "PLAN_NOT_FOUND") unless plan

      return failure("Proof of payment is required", code: "PROOF_REQUIRED") if @proof.blank?

      order = SubscriptionPaymentOrder.create!(
        business: @business,
        plan: plan,
        amount: plan.price_monthly,
        due_date: Date.current,
        period_start: Date.current,
        period_end: Date.current + 1.month,
        status: "proof_submitted",
        proof_submitted_at: Time.current
      )

      order.proof.attach(@proof)

      NotifyAdminSubscriptionProofJob.perform_later(order.id)

      AdminNotification.notify!(
        title: "Nuevo comprobante de pago",
        body: "#{@business.name} envio comprobante para Plan #{plan.name} ($#{order.amount.to_i})",
        notification_type: "subscription_proof",
        link: "/admin/subscription_payment_orders/#{order.id}",
        icon: "💳"
      )

      success({ order_id: order.id, status: order.status })
    end
  end
end
