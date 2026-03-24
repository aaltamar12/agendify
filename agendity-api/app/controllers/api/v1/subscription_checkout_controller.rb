# frozen_string_literal: true

module Api
  module V1
    # Handles the subscription checkout flow for businesses:
    #   - View available plans
    #   - Get payment info (bank accounts, Nequi, etc.)
    #   - Submit payment proof
    #   - Check subscription/trial status
    class SubscriptionCheckoutController < BaseController
      skip_before_action :require_business!, only: [:plans, :payment_info, :status]
      skip_before_action :render_empty_for_admin_without_business!

      # GET /api/v1/subscription/plans
      def plans
        plans = Plan.order(:price_monthly)
        render_success(plans.map { |p|
          {
            id: p.id,
            name: p.name,
            price_monthly: p.price_monthly.to_f,
            price_monthly_usd: p.price_monthly_usd&.to_f,
            max_employees: p.max_employees,
            max_services: p.max_services,
            max_reservations_month: p.max_reservations_month,
            ai_features: p.ai_features,
            ticket_digital: p.ticket_digital,
            advanced_reports: p.advanced_reports
          }
        })
      end

      # GET /api/v1/subscription/payment_info
      def payment_info
        render_success({
          nequi: SiteConfig.get("payment_nequi"),
          bancolombia: SiteConfig.get("payment_bancolombia"),
          daviplata: SiteConfig.get("payment_daviplata"),
          support_whatsapp: SiteConfig.get("support_whatsapp"),
          support_email: SiteConfig.get("support_email")
        })
      end

      # POST /api/v1/subscription/checkout
      def checkout
        result = Subscriptions::CheckoutService.call(
          business: current_business,
          plan_id: params[:plan_id],
          proof: params[:proof]
        )

        if result.success?
          render_success(result.data, status: :created)
        else
          render_error(result.error, status: :unprocessable_entity, code: result.error_code)
        end
      end

      # GET /api/v1/subscription/status
      def status
        business = current_business
        return render_success({ admin: true }) unless business

        active_subscription = business.subscriptions.active.where("end_date >= ?", Date.current).order(end_date: :desc).first
        pending_order = business.subscription_payment_orders.proof_submitted.order(created_at: :desc).first

        render_success({
          trial_ends_at: business.trial_ends_at&.iso8601,
          trial_active: business.trial_ends_at.present? && business.trial_ends_at > Time.current,
          trial_days_remaining: business.trial_ends_at.present? ? [(business.trial_ends_at.to_date - Date.current).to_i, 0].max : nil,
          has_active_subscription: active_subscription.present?,
          had_subscription: business.subscriptions.exists?,
          subscription: active_subscription ? {
            id: active_subscription.id,
            plan_name: active_subscription.plan.name,
            start_date: active_subscription.start_date.iso8601,
            end_date: active_subscription.end_date.iso8601,
            status: active_subscription.status
          } : nil,
          pending_order: pending_order ? {
            id: pending_order.id,
            plan_name: (pending_order.plan || pending_order.subscription&.plan)&.name,
            amount: pending_order.amount.to_f,
            submitted_at: pending_order.proof_submitted_at&.iso8601,
            status: pending_order.status
          } : nil,
          business_status: business.status
        })
      end
    end
  end
end
