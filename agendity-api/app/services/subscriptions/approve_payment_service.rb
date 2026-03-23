# frozen_string_literal: true

module Subscriptions
  # Approves a proof-submitted payment order:
  #   1. Creates or extends a Subscription
  #   2. Marks order as paid
  #   3. Reactivates business if suspended
  #   4. Activates referral if pending
  #   5. Sends email + in-app notification
  class ApprovePaymentService < BaseService
    def initialize(order:, reviewed_by:)
      @order       = order
      @reviewed_by = reviewed_by
    end

    def call
      return failure("Order is not in proof_submitted status") unless @order.status == "proof_submitted"

      plan = @order.plan || @order.subscription&.plan
      return failure("No plan associated with this order") unless plan

      business = @order.business

      ActiveRecord::Base.transaction do
        # Create or extend subscription
        subscription = create_or_extend_subscription!(business, plan)

        # Mark order as paid
        @order.update!(
          status: "paid",
          subscription: subscription,
          reviewed_by: @reviewed_by,
          reviewed_at: Time.current
        )

        # Reactivate business if suspended
        business.active! if business.suspended?

        # Activate referral if pending
        referral = business.referral
        referral.activate!(subscription) if referral&.pending?
      end

      # Send notifications (outside transaction)
      send_notifications!(business)

      success({ order_id: @order.id, subscription_id: @order.subscription_id })
    end

    private

    def create_or_extend_subscription!(business, plan)
      existing = business.subscriptions.active.where(plan: plan).first

      if existing
        existing.update!(end_date: existing.end_date + 1.month)
        existing
      else
        business.subscriptions.create!(
          plan: plan,
          start_date: Date.current,
          end_date: Date.current + 1.month,
          status: :active
        )
      end
    end

    def send_notifications!(business)
      subscription = @order.subscription

      # Email
      BusinessMailer.subscription_activated(business, subscription).deliver_later

      # In-app notification
      notification = Notification.create!(
        business: business,
        title: "Suscripcion activada",
        body: "Tu plan #{subscription.plan.name} ha sido activado hasta el #{subscription.end_date.strftime('%d/%m/%Y')}.",
        notification_type: "subscription_expiry",
        link: "/dashboard/settings"
      )

      # Real-time push via NATS
      Realtime::NatsPublisher.publish(
        business_id: business.id,
        event: "subscription_activated",
        data: {
          notification_id: notification.id,
          plan_name: subscription.plan.name,
          end_date: subscription.end_date.iso8601
        }
      )
    end
  end
end
