# frozen_string_literal: true

module Credits
  # Reconciles CreditAccount balances against the sum of their CreditTransactions.
  # For each account: expected = SUM(amount) from CreditTransactions
  # Compares with current CreditAccount.balance and reports discrepancies.
  class ReconciliationService < BaseService
    def initialize(business:, fix: false)
      @business = business
      @fix = fix
    end

    def call
      discrepancies = []

      @business.credit_accounts.includes(:customer, :credit_transactions).find_each do |account|
        expected = account.credit_transactions.sum(:amount)
        # Balance should never be negative, so floor at 0
        expected = [expected, 0].max
        actual = account.balance || 0

        difference = (expected - actual).round(2)
        next if difference.zero?

        if @fix
          account.update!(balance: expected)
        end

        discrepancies << {
          credit_account_id: account.id,
          customer_id: account.customer_id,
          customer_name: account.customer&.name,
          expected: expected.to_f,
          actual: actual.to_f,
          difference: difference.to_f,
          fixed: @fix
        }
      end

      success(discrepancies)
    end
  end
end
