# frozen_string_literal: true

module Api
  module V1
    # Reconciliation endpoints for cash register and credit balances.
    # Plan enforcement: requires ai_features (Plan Inteligente).
    class ReconciliationController < BaseController
      before_action :require_intelligent_plan!

      # GET /api/v1/reconciliation/check
      # Runs both cash register and credits reconciliation.
      def check
        cash_result = CashRegister::ReconciliationService.call(business: current_business)
        credits_result = Credits::ReconciliationService.call(business: current_business)

        render_success({
          cash_register: {
            ok: cash_result.data.empty?,
            discrepancies: cash_result.data
          },
          credits: {
            ok: credits_result.data.empty?,
            discrepancies: credits_result.data
          }
        })
      end

      private

      def require_intelligent_plan!
        unless current_business.has_feature?(:ai_features)
          render_error(
            "La reconciliacion requiere Plan Inteligente.",
            status: :forbidden
          )
        end
      end
    end
  end
end
