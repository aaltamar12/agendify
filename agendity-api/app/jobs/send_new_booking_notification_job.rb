# frozen_string_literal: true

# Sends a new-booking notification email to the business owner
# and creates an in-app notification.
class SendNewBookingNotificationJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)
    AppointmentMailer.new_booking(appointment).deliver_now

    # In-app notification for the business
    Notification.create!(
      business: appointment.business,
      title: "Nueva reserva de #{appointment.customer.name}",
      body: "#{appointment.service.name} — #{appointment.appointment_date}",
      notification_type: "new_booking",
      link: "/dashboard/agenda?date=#{appointment.appointment_date}"
    )

    # Activity log
    ActivityLog.log(
      business: appointment.business,
      action: "notification_sent",
      description: "Notificación de nueva reserva enviada al negocio",
      actor_type: "system",
      resource: appointment
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: appointment.business_id,
      event: "new_booking",
      data: {
        appointment_id: appointment.id,
        customer_name: appointment.customer&.name,
        service_name: appointment.service&.name
      }
    )
  end
end
