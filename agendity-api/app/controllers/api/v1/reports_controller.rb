# frozen_string_literal: true

module Api
  module V1
    # Read-only reports and analytics scoped to the current business.
    # SRP: Only handles HTTP concerns; delegates data aggregation to services.
    class ReportsController < BaseController
      # GET /api/v1/reports/summary
      def summary
        result = Reports::SummaryService.call(business: current_business)

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/reports/revenue
      def revenue
        result = Reports::RevenueService.call(business: current_business, period: params[:period])

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/reports/top_services
      def top_services
        data = current_business.appointments
          .where.not(status: :cancelled)
          .joins(:service)
          .group("services.name")
          .order("count_all DESC")
          .limit(10)
          .count
          .map { |name, count| { name: name, count: count } }

        render_success(data)
      end

      # GET /api/v1/reports/top_employees
      def top_employees
        data = current_business.appointments
          .where.not(status: :cancelled)
          .joins(:employee)
          .group("employees.name")
          .order("count_all DESC")
          .limit(10)
          .count
          .map { |name, count| { name: name, count: count } }

        render_success(data)
      end

      # GET /api/v1/reports/profit
      def profit
        period = params[:period] || "month"
        from_date = case period
                    when "week" then 1.week.ago.to_date
                    when "month" then 1.month.ago.to_date
                    when "year" then 1.year.ago.to_date
                    else 1.month.ago.to_date
                    end

        revenue = current_business.appointments
          .where(status: [:checked_in, :completed])
          .where("appointment_date >= ?", from_date)
          .sum(:price).to_f

        employee_payments_total = EmployeePayment
          .joins(:cash_register_close)
          .where(cash_register_closes: { business_id: current_business.id })
          .where("cash_register_closes.date >= ?", from_date)
          .sum(:amount_paid).to_f

        credits_issued = CreditTransaction
          .joins(:credit_account)
          .where(credit_accounts: { business_id: current_business.id })
          .where("credit_transactions.created_at >= ?", from_date)
          .where(transaction_type: [:cashback, :cancellation_refund])
          .sum(:amount).to_f

        credits_redeemed = CreditTransaction
          .joins(:credit_account)
          .where(credit_accounts: { business_id: current_business.id })
          .where("credit_transactions.created_at >= ?", from_date)
          .where(transaction_type: :redemption)
          .sum(:amount).to_f.abs

        # Penalty income from cancellations (money the business retains)
        # For Pro+ plans: tracked via CreditTransaction penalty amounts
        # For Basic: tracked via pending_penalty applied to next booking (already in revenue)
        penalty_income = current_business.appointments
          .where(status: :cancelled)
          .where("appointment_date >= ?", from_date)
          .where.not(cancelled_by: "business")
          .sum("price * #{current_business.cancellation_policy_pct} / 100.0").to_f

        total_income = revenue + penalty_income
        net_profit = total_income - employee_payments_total
        closes_count = current_business.cash_register_closes.where("date >= ?", from_date).closed.count

        render_success({
          period: period,
          from_date: from_date,
          revenue: revenue,
          penalty_income: penalty_income,
          total_income: total_income,
          employee_payments: employee_payments_total,
          net_profit: net_profit,
          credits_issued: credits_issued,
          credits_redeemed: credits_redeemed,
          cash_register_closes: closes_count,
          pending_employee_debt: current_business.employees.sum(:pending_balance).to_f,
          total_credits_in_circulation: current_business.credit_accounts.sum(:balance).to_f
        })
      end

      # GET /api/v1/reports/frequent_customers
      def frequent_customers
        data = current_business.appointments
          .where.not(status: :cancelled)
          .joins(:customer)
          .group("customers.name", "customers.email")
          .order("count_all DESC")
          .limit(20)
          .count
          .map { |(name, email), count| { name: name, email: email, visits: count } }

        render_success(data)
      end
    end
  end
end
