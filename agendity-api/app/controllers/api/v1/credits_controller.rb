# frozen_string_literal: true

module Api
  module V1
    class CreditsController < BaseController
      # GET /api/v1/credits/summary
      def summary
        accounts = current_business.credit_accounts
          .includes(:customer)
          .where("balance > 0")
          .order(balance: :desc)
        render_success(CreditAccountSerializer.render_as_hash(accounts))
      end

      # GET /api/v1/customers/:customer_id/credits
      def show
        customer = current_business.customers.find(params[:customer_id])
        account = CreditAccount.find_by(customer: customer, business: current_business)

        if account
          transactions = account.credit_transactions.order(created_at: :desc).limit(50)
          render_success({
            balance: account.balance.to_f,
            transactions: CreditTransactionSerializer.render_as_hash(transactions)
          })
        else
          render_success({ balance: 0, transactions: [] })
        end
      end

      # POST /api/v1/customers/:customer_id/credits/adjust
      def adjust
        customer = current_business.customers.find(params[:customer_id])

        result = Credits::AdjustService.call(
          customer: customer,
          business: current_business,
          amount: params[:amount],
          description: params[:description],
          performed_by: current_user
        )

        if result.success?
          render_success({ balance: result.data.balance.to_f })
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/customers/:customer_id/credit_balance
      # Quick balance check (used in appointment creation modal)
      def balance
        customer = current_business.customers.find(params[:customer_id])
        account = CreditAccount.find_by(customer: customer, business: current_business)
        render_success({ balance: account&.balance.to_f || 0 })
      end
    end
  end
end
