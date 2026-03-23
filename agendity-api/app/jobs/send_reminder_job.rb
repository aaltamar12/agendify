# frozen_string_literal: true

# Sends appointment reminder to the customer via MultiChannel (email + WhatsApp for Pro+).
class SendReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)

    # Only send reminder if the appointment is still confirmed
    return unless appointment.confirmed?

    customer = appointment.customer
    business = appointment.business
    return unless customer.present?

    # Notify customer via MultiChannel (email always, WhatsApp if Pro+)
    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :appointment_reminder,
      business: business,
      data: {
        appointment: appointment,
        business_name: business.name,
        service_name: appointment.service&.name,
        employee_name: appointment.employee&.name,
        appointment_date: appointment.appointment_date,
        start_time: appointment.start_time
      }
    )

    # Activity log
    ActivityLog.log(
      business: business,
      action: "reminder_sent",
      description: "Recordatorio enviado a #{customer.name}",
      actor_type: "system",
      resource: appointment
    )
  end
end
