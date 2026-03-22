# frozen_string_literal: true

module Api
  module V1
    # Cash register management: daily summary, close, and history.
    # Restricted to Profesional+ plans.
    class CashRegisterController < BaseController
      before_action :require_professional_plan!

      # GET /api/v1/cash_register/today
      def today
        date = params[:date] || Date.current
        result = CashRegister::DailySummaryService.call(business: current_business, date: date)

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # POST /api/v1/cash_register/close
      def close
        result = CashRegister::CloseService.call(
          business: current_business,
          user: current_user,
          date: params[:date],
          employee_payments: params[:employee_payments]&.map(&:to_unsafe_h),
          notes: params[:notes]
        )

        if result.success?
          render_success(
            CashRegisterCloseSerializer.render_as_hash(result.data, view: :with_payments),
            status: :created
          )
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/cash_register/history
      def history
        closes = current_business.cash_register_closes.recent
        closes = closes.where("date >= ?", params[:from]) if params[:from].present?
        closes = closes.where("date <= ?", params[:to]) if params[:to].present?
        render_success(CashRegisterCloseSerializer.render_as_hash(closes, view: :with_payments))
      end

      # GET /api/v1/cash_register/:id
      def show
        close = current_business.cash_register_closes.find(params[:id])
        render_success(CashRegisterCloseSerializer.render_as_hash(close, view: :detailed))
      end

      private

      def require_professional_plan!
        unless current_business.has_feature?(:advanced_reports)
          render_error(
            "El cierre de caja requiere Plan Profesional o superior.",
            status: :forbidden
          )
        end
      end
    end
  end
end
