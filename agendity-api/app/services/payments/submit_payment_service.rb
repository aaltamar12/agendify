# frozen_string_literal: true

module Payments
  # Creates a payment record attached to an appointment and moves
  # the appointment to the payment_sent status.
  class SubmitPaymentService < BaseService
    def initialize(appointment:, payment_method:, amount:, proof_image_url: nil, additional_info: nil)
      @appointment     = appointment
      @payment_method  = payment_method
      @amount          = amount
      @proof_image_url = proof_image_url
      @additional_info = additional_info
    end

    def call
      ActiveRecord::Base.transaction do
        payment = @appointment.build_payment(
          payment_method:  @payment_method,
          amount:          @amount,
          proof_image_url: @proof_image_url,
          additional_info: @additional_info,
          status:          :submitted
        )

        unless payment.save
          return failure("Could not create payment", details: payment.errors.full_messages)
        end

        unless @appointment.update(status: :payment_sent)
          return failure("Could not update appointment status", details: @appointment.errors.full_messages)
        end

        ::SendPaymentSubmittedJob.perform_later(payment.id)

        ActivityLog.log(
          business: @appointment.business,
          action: "payment_submitted",
          description: "Comprobante recibido de #{@appointment.customer&.name}",
          actor_type: "customer",
          actor_name: @appointment.customer&.name,
          resource: @appointment,
          metadata: { payment_id: payment.id, amount: @amount, payment_method: @payment_method }
        )

        success(payment)
      end
    end
  end
end
