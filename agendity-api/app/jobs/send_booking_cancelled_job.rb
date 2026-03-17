# frozen_string_literal: true

# Sends a cancellation email to both the business and the customer
# and creates an in-app notification with context about who cancelled.
class SendBookingCancelledJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)
    AppointmentMailer.booking_cancelled(appointment).deliver_now

    # In-app notification for the business
    Notification.create!(
      business: appointment.business,
      title: "Cita cancelada: #{appointment.service.name} — #{appointment.customer.name}",
      body: cancellation_body(appointment),
      notification_type: "booking_cancelled",
      link: "/dashboard/agenda?date=#{appointment.appointment_date}"
    )

    # Activity log
    ActivityLog.log(
      business: appointment.business,
      action: "notification_sent",
      description: "Notificación de cancelación enviada para #{appointment.customer&.name}",
      actor_type: "system",
      resource: appointment
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: appointment.business_id,
      event: "booking_cancelled",
      data: {
        appointment_id: appointment.id,
        customer_name: appointment.customer&.name,
        service_name: appointment.service&.name
      }
    )
  end

  private

  def cancellation_body(appointment)
    if appointment.respond_to?(:cancelled_by) && appointment.cancelled_by == "business"
      "Cancelada por #{appointment.business.name}"
    elsif appointment.respond_to?(:cancelled_by) && appointment.cancelled_by == "customer"
      reason = appointment.cancellation_reason.presence
      "El cliente canceló#{reason ? ": #{reason}" : ""}"
    else
      appointment.cancellation_reason.presence || "Cancelada"
    end
  end
end
