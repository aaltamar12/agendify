# frozen_string_literal: true

module Api
  module V1
    # Handles payment submission, approval, and rejection for appointments.
    # SRP: Only handles HTTP concerns; delegates payment logic to services.
    class PaymentsController < BaseController
      # POST /api/v1/appointments/:appointment_id/payments
      # POST /api/v1/payments/:id/submit
      def submit
        appointment = current_business.appointments.find(params[:appointment_id])
        result = Payments::SubmitPaymentService.call(appointment: appointment, **payment_params.to_h.symbolize_keys)

        if result.success?
          render_success(PaymentSerializer.render_as_hash(result.data), status: :created)
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/payments/:id/approve
      def approve
        payment = find_payment
        result = Payments::ApprovePaymentService.call(payment: payment)

        if result.success?
          render_success(PaymentSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/payments/:id/reject
      def reject
        payment = find_payment
        result = Payments::RejectPaymentService.call(
          payment: payment,
          reason: params[:rejection_reason]
        )

        if result.success?
          render_success(PaymentSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      private

      def find_payment
        Payment.joins(:appointment)
               .where(appointments: { business_id: current_business.id })
               .find(params[:id])
      end

      def payment_params
        permitted = params.require(:payment).permit(:payment_method, :reference, :proof, :amount)
        # Map frontend proof to backend proof_image_url
        if permitted.key?(:proof)
          permitted[:proof_image_url] = permitted.delete(:proof)
        end
        permitted
      end
    end
  end
end
