# frozen_string_literal: true

module Credits
  # Manual adjustment of a customer's credit balance by the business.
  class AdjustService < BaseService
    def initialize(customer:, business:, amount:, description:, performed_by:)
      @customer = customer
      @business = business
      @amount = amount.to_d
      @description = description.presence || "Ajuste manual"
      @performed_by = performed_by
    end

    def call
      return failure("El monto no puede ser cero", code: "ZERO_AMOUNT") if @amount.zero?

      account = CreditAccount.find_or_create_by!(customer: @customer, business: @business)

      if @amount.positive?
        account.credit!(
          @amount,
          transaction_type: :manual_adjustment,
          description: @description,
          performed_by: @performed_by
        )
      else
        account.debit!(
          @amount.abs,
          transaction_type: :manual_adjustment,
          description: @description,
          performed_by: @performed_by
        )
      end

      success(account.reload)
    end
  end
end
