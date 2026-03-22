# frozen_string_literal: true

module Credits
  # Awards cashback credits to a customer after appointment completion.
  class CashbackService < BaseService
    def initialize(appointment:)
      @appointment = appointment
      @business = appointment.business
      @customer = appointment.customer
    end

    def call
      return success(nil) unless @business.cashback_enabled?
      return success(nil) unless @business.cashback_percentage&.positive?
      return success(nil) unless @customer.present?

      cashback_amount = (@appointment.price * @business.cashback_percentage / 100).round(2)
      return success(nil) if cashback_amount.zero?

      account = CreditAccount.find_or_create_by!(customer: @customer, business: @business)
      account.credit!(
        cashback_amount,
        transaction_type: :cashback,
        description: "Cashback #{@business.cashback_percentage}% — #{@appointment.service&.name}",
        appointment: @appointment
      )

      success(cashback_amount)
    end
  end
end
