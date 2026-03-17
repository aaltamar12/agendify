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
