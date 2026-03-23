# frozen_string_literal: true

module Api
  module V1
    # CRUD and state transitions for appointments scoped to the current business.
    # SRP: Only handles HTTP concerns; delegates state transitions to services.
    class AppointmentsController < BaseController
      before_action :set_appointment, only: %i[show update confirm checkin cancel complete remind_payment]

      # GET /api/v1/appointments
      def index
        appointments = current_business.appointments.includes(:service, :employee, :customer, :payment, appointment_services: :service)
        appointments = appointments.where(appointment_date: params[:date]) if params[:date].present?
        appointments = appointments.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        appointments = appointments.where(status: params[:status]) if params[:status].present?

        # Filter by payment status (e.g. payment_status=rejected)
        if params[:payment_status].present?
          appointments = appointments.joins(:payment).where(payments: { status: params[:payment_status] })
        end

        render_success(AppointmentSerializer.render_as_hash(appointments, view: :detailed))
      end

      # GET /api/v1/appointments/:id
      def show
        render_success(AppointmentSerializer.render_as_hash(@appointment, view: :detailed))
      end

      # POST /api/v1/appointments
      def create
        result = Appointments::CreateAppointmentService.call(business: current_business, params: appointment_params)

        if result.success?
          appointment = result.data[:appointment]
          render_success(AppointmentSerializer.render_as_hash(appointment, view: :detailed), status: :created)
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # PATCH /api/v1/appointments/:id
      def update
        authorize @appointment

        if @appointment.update(appointment_params)
          render_success(AppointmentSerializer.render_as_hash(@appointment, view: :detailed))
        else
          render_error(
            @appointment.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: @appointment.errors.messages
          )
        end
      end

      # POST /api/v1/appointments/:id/confirm
      def confirm
        result = Appointments::ConfirmPaymentService.call(appointment: @appointment)

        if result.success?
          render_success(AppointmentSerializer.render_as_hash(result.data, view: :detailed))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/appointments/:id/checkin
      def checkin
        result = Appointments::CheckinService.call(appointment: @appointment)

        if result.success?
          render_success(AppointmentSerializer.render_as_hash(result.data, view: :detailed))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/appointments/checkin_by_code
      def checkin_by_code
        appointment = current_business.appointments
                        .includes(:service, :employee, :customer)
                        .find_by!(ticket_code: params[:ticket_code])

        result = Appointments::CheckinService.call(appointment: appointment)

        if result.success?
          render_success(AppointmentSerializer.render_as_hash(result.data, view: :detailed))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/appointments/:id/cancel
      def cancel
        result = Appointments::CancelAppointmentService.call(
          appointment: @appointment,
          cancelled_by: "business",
          reason: params[:cancellation_reason]
        )

        if result.success?
          render_success(AppointmentSerializer.render_as_hash(result.data[:appointment], view: :detailed))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/appointments/:id/complete
      def complete
        result = Appointments::CompleteService.call(appointment: @appointment)

        if result.success?
          render_success(AppointmentSerializer.render_as_hash(result.data, view: :detailed))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # GET /api/v1/appointments/available_slots
      def available_slots
        result = Bookings::AvailabilityService.call(
          business: current_business,
          service_id: params[:service_id],
          date: params[:date],
          employee_id: params[:employee_id]
        )

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # POST /api/v1/appointments/:id/remind_payment
      # Sends a payment reminder email to the customer.
      def remind_payment
        customer = @appointment.customer
        unless customer&.email.present?
          return render_error("El cliente no tiene email registrado", status: :unprocessable_entity)
        end

        unless @appointment.pending_payment?
          return render_error("La cita no está pendiente de pago", status: :unprocessable_entity)
        end

        Notifications::MultiChannelService.call(
          recipient: customer,
          template: :payment_reminder,
          business: current_business,
          data: {
            appointment: @appointment,
            business_name: current_business.name,
            service_name: @appointment.service&.name
          }
        )

        ActivityLog.log(
          business: current_business,
          action: "payment_reminder_sent",
          description: "Recordatorio de pago enviado a #{customer.name}",
          actor_type: "business",
          resource: @appointment,
          metadata: { customer_email: customer.email }
        )

        render_success({ message: "Recordatorio enviado exitosamente" })
      end

      private

      def set_appointment
        @appointment = current_business.appointments.find(params[:id])
      end

      def appointment_params
        params.require(:appointment).permit(
          :service_id, :employee_id, :customer_name, :customer_email,
          :customer_phone, :customer_birth_date, :appointment_date, :start_time,
          :notes, :discount_code,
          additional_service_ids: []
        )
      end
    end
  end
end
