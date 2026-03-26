# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public ticket lookup and cancellation by code (no auth required).
      # SRP: Only handles HTTP concerns for public ticket viewing and customer cancellation.
      class TicketsController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # GET /api/v1/public/tickets/:code
        def show
          appointment = find_appointment
          render_success({
            appointment: AppointmentSerializer.render_as_hash(appointment, view: :detailed),
            business: BusinessSerializer.render_as_hash(appointment.business, view: :with_payment),
            ticket_vip: appointment.business.has_feature?(:ticket_digital)
          })
        end

        # POST /api/v1/public/tickets/:code/payment
        # Allows unauthenticated customers to upload a payment proof directly.
        # Requires customer_email to verify identity.
        def submit_payment
          appointment = find_appointment

          # Validate customer identity
          customer_email = params[:customer_email]&.strip&.downcase
          unless customer_email.present? && appointment.customer&.email&.downcase == customer_email
            return render_error(
              "No se pudo verificar tu identidad. Asegúrate de usar el mismo correo con el que reservaste.",
              status: :forbidden
            )
          end

          # Validate appointment is in correct status
          unless appointment.pending_payment?
            return render_error(
              "Esta cita no está pendiente de pago.",
              status: :unprocessable_entity
            )
          end

          proof_url = nil
          if params[:proof].present? && params[:proof].is_a?(ActionDispatch::Http::UploadedFile)
            appointment.proof_image.attach(params[:proof])
            proof_url = Rails.application.routes.url_helpers.rails_blob_url(
              appointment.proof_image,
              host: request.base_url
            )
          end

          result = Payments::SubmitPaymentService.call(
            appointment: appointment,
            payment_method: params[:payment_method] || "transfer",
            amount: appointment.price,
            proof_image_url: proof_url,
            additional_info: params[:additional_info]
          )

          if result.success?
            render_success({
              status: "submitted",
              message: "Comprobante enviado exitosamente",
              appointment: AppointmentSerializer.render_as_hash(appointment.reload, view: :detailed)
            })
          else
            render_error(result.error, status: :unprocessable_entity, details: result.details)
          end
        end

        # GET /api/v1/public/tickets/:code/cancel_preview
        def cancel_preview
          appointment = find_appointment
          business = appointment.business

          has_paid = %w[payment_sent confirmed checked_in].include?(appointment.status)
          deadline_hours = business.cancellation_deadline_hours
          policy_pct = business.cancellation_policy_pct

          # Calculate if past deadline
          appointment_time = Time.zone.parse(
            "#{appointment.appointment_date} #{appointment.start_time.strftime('%H:%M')}"
          ).in_time_zone(business.timezone || "America/Bogota")
          now = Time.current.in_time_zone(business.timezone || "America/Bogota")
          hours_until = (appointment_time - now) / 1.hour
          deadline_passed = hours_until < deadline_hours

          penalty_amount = 0
          refund_amount = 0

          if deadline_passed && policy_pct.positive?
            penalty_amount = (appointment.price * policy_pct / 100.0).round(2)
          end

          if has_paid
            refund_amount = (appointment.price - penalty_amount).round(2)
          end

          plan = business.current_plan
          refund_as_credit = plan&.cashback_enabled? || false

          render_success({
            can_cancel: !appointment.cancelled? && !appointment.completed?,
            has_paid: has_paid,
            deadline_hours: deadline_hours,
            deadline_passed: deadline_passed,
            hours_until_appointment: hours_until.round(1),
            penalty_pct: deadline_passed ? policy_pct : 0,
            penalty_amount: penalty_amount,
            refund_amount: refund_amount,
            refund_as_credit: refund_as_credit,
            business_contact: {
              name: business.name,
              phone: business.phone,
              email: business.email,
              address: [business.address, business.city].compact.join(", ")
            }
          })
        end

        # POST /api/v1/public/tickets/:code/cancel
        def cancel
          appointment = find_appointment

          result = Appointments::CancelAppointmentService.call(
            appointment: appointment,
            cancelled_by: "customer",
            reason: params[:reason]
          )

          if result.success?
            render_success({
              appointment: AppointmentSerializer.render_as_hash(result.data[:appointment], view: :detailed),
              penalty_applied: result.data[:penalty_applied],
              penalty_amount: result.data[:penalty_amount]
            })
          else
            render_error(result.error, status: :unprocessable_entity, details: result.details)
          end
        end

        private

        def find_appointment
          Appointment.includes(:service, :employee, :customer, :payment, :business)
                     .find_by!(ticket_code: params[:code])
        end
      end
    end
  end
end
