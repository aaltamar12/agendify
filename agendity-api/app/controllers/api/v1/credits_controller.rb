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

      # GET /api/v1/customers/:id/credits
      def show
        customer = current_business.customers.find(params[:id])
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

      # POST /api/v1/customers/:id/credits/adjust
      def adjust
        customer = current_business.customers.find(params[:id])

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

      # POST /api/v1/credits/bulk_adjust
      # Applies credit to multiple customers or all customers
      def bulk_adjust
        amount = params[:amount].to_d
        return render_error("Monto requerido", status: :unprocessable_entity) if amount.zero?

        description = params[:description].presence || "Credito masivo"
        customer_ids = params[:customer_ids]

        customers = if customer_ids.present?
          current_business.customers.where(id: customer_ids)
        else
          current_business.customers.all
        end

        count = 0
        customers.find_each do |customer|
          Credits::AdjustService.call(
            customer: customer,
            business: current_business,
            amount: amount,
            description: description,
            performed_by: current_user
          )
          count += 1
        end

        render_success({ message: "Credito aplicado a #{count} clientes", count: count })
      end

      # GET /api/v1/customers/:id/credit_balance
      def balance
        customer = current_business.customers.find(params[:id])
        account = CreditAccount.find_by(customer: customer, business: current_business)
        render_success({ balance: account&.balance.to_f || 0 })
      end
    end
  end
end
