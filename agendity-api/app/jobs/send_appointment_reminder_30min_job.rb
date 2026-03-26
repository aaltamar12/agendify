# frozen_string_literal: true

# Sends a 30-minute-before reminder to the customer via MultiChannel (email + WhatsApp for Pro+).
# Scheduled via `set(wait_until:)` when the appointment is confirmed.
class SendAppointmentReminder30minJob < ApplicationJob
  queue_as :notifications

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find_by(id: appointment_id)
    return unless appointment
    return unless appointment.confirmed? || appointment.checked_in?

    customer = appointment.customer
    business = appointment.business
    return unless customer.present?

    # Notify customer via MultiChannel (email always, WhatsApp if Pro+)
    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :appointment_reminder_30min,
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
      action: "reminder_30min_sent",
      description: "Recordatorio de 30 min enviado a #{customer.name}",
      actor_type: "system",
      resource: appointment
    )
  end
end
