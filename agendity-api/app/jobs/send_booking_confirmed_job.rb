# frozen_string_literal: true

# Sends booking confirmation to the customer via MultiChannel (email + WhatsApp for Pro+).
class SendBookingConfirmedJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)
    customer = appointment.customer
    business = appointment.business
    return unless customer.present?

    # Notify customer via MultiChannel (email always, WhatsApp if Pro+)
    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :booking_confirmed,
      business: business,
      data: {
        appointment: appointment,
        business_name: business.name,
        service_name: appointment.service&.name,
        employee_name: appointment.employee&.name,
        appointment_date: appointment.appointment_date,
        start_time: appointment.start_time,
        ticket_code: appointment.ticket_code
      }
    )

    # Activity log
    ActivityLog.log(
      business: business,
      action: "notification_sent",
      description: "Confirmación de pago enviada al cliente #{customer.name}",
      actor_type: "system",
      resource: appointment
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: business.id,
      event: "booking_confirmed",
      data: {
        appointment_id: appointment.id,
        customer_name: customer.name,
        service_name: appointment.service&.name
      }
    )
  end
end
