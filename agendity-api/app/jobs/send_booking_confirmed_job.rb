# frozen_string_literal: true

# Sends a confirmation email with ticket code to the customer.
class SendBookingConfirmedJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)
    AppointmentMailer.booking_confirmed(appointment).deliver_now

    # Activity log
    ActivityLog.log(
      business: appointment.business,
      action: "notification_sent",
      description: "Confirmación de pago enviada al cliente #{appointment.customer&.name}",
      actor_type: "system",
      resource: appointment
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: appointment.business_id,
      event: "booking_confirmed",
      data: {
        appointment_id: appointment.id,
        customer_name: appointment.customer&.name,
        service_name: appointment.service&.name
      }
    )
  end
end
