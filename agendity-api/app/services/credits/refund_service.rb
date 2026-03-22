# frozen_string_literal: true

module Credits
  # Refunds a cancelled appointment as credits (minus penalty).
  class RefundService < BaseService
    def initialize(appointment:)
      @appointment = appointment
      @business = appointment.business
      @customer = appointment.customer
    end

    def call
      return success(nil) unless @business.cancellation_refund_as_credit?
      return success(nil) unless @customer.present?

      account = CreditAccount.find_or_create_by!(customer: @customer, business: @business)

      penalty_pct = @business.cancellation_policy_pct || 0
      penalty_amount = (@appointment.price * penalty_pct / 100).round(2)
      refund_amount = (@appointment.price - penalty_amount).round(2)

      if refund_amount.positive?
        account.credit!(
          refund_amount,
          transaction_type: :cancellation_refund,
          description: "Reembolso por cancelacion — #{@appointment.service&.name}",
          appointment: @appointment
        )
      end

      success({ refund: refund_amount, penalty: penalty_amount })
    end
  end
end
