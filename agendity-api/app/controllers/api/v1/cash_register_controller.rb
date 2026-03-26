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
          render_error(result.error, status: :unprocessable_entity, code: result.error_code)
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

      # POST /api/v1/cash_register/upload_proof
      def upload_proof
        payment = EmployeePayment.joins(:cash_register_close)
          .where(cash_register_closes: { business_id: current_business.id })
          .find(params[:employee_payment_id])

        unless params[:proof].present?
          return render_error("No se envió ningún archivo", status: :unprocessable_entity)
        end

        payment.proof.attach(params[:proof])
        render_success({ attached: payment.proof.attached?, employee_payment_id: payment.id })
      end

      # GET /api/v1/cash_register/:id/employee_payments/:employee_payment_id/receipt
      def employee_payment_receipt
        close = current_business.cash_register_closes.find(params[:id])
        payment = close.employee_payments.find(params[:employee_payment_id])

        result = CashRegister::GeneratePaymentReceiptService.call(employee_payment: payment)

        if result.success?
          send_data result.data,
            filename: "recibo-#{payment.employee.name.parameterize}-#{close.date}.pdf",
            type: "application/pdf",
            disposition: "attachment"
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # DELETE /api/v1/cash_register/delete_proof
      def delete_proof
        payment = EmployeePayment.joins(:cash_register_close)
          .where(cash_register_closes: { business_id: current_business.id })
          .find(params[:employee_payment_id])

        payment.proof.purge if payment.proof.attached?
        render_success({ deleted: true, employee_payment_id: payment.id })
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
