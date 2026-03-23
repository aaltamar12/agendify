# frozen_string_literal: true

# Sends cancellation notifications:
# - To business: email (direct) + in-app + NATS
# - To customer: via MultiChannel (email + WhatsApp for Pro+)
class SendBookingCancelledJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)
    customer = appointment.customer
    business = appointment.business

    # Notify business directly (email + in-app + NATS)
    AppointmentMailer.booking_cancelled(appointment).deliver_now

    Notification.create!(
      business: business,
      title: "Cita cancelada: #{appointment.service.name} — #{customer.name}",
      body: cancellation_body(appointment),
      notification_type: "booking_cancelled",
      link: "/dashboard/agenda?date=#{appointment.appointment_date}"
    )

    Realtime::NatsPublisher.publish(
      business_id: business.id,
      event: "booking_cancelled",
      data: {
        appointment_id: appointment.id,
        customer_name: customer.name,
        service_name: appointment.service&.name
      }
    )

    # Notify customer via MultiChannel (email always, WhatsApp if Pro+)
    if customer.present?
      Notifications::MultiChannelService.call(
        recipient: customer,
        template: :booking_cancelled,
        business: business,
        data: {
          appointment: appointment,
          business_name: business.name,
          service_name: appointment.service&.name,
          appointment_date: appointment.appointment_date,
          start_time: appointment.start_time
        }
      )
    end

    # Activity log
    ActivityLog.log(
      business: business,
      action: "notification_sent",
      description: "Notificación de cancelación enviada para #{customer&.name}",
      actor_type: "system",
      resource: appointment
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
