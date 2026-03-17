# frozen_string_literal: true

# Sends a reminder email to the customer 24 hours before the appointment.
class SendReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.includes(:business, :service, :employee, :customer).find(appointment_id)

    # Only send reminder if the appointment is still confirmed
    return unless appointment.confirmed?

    AppointmentMailer.reminder(appointment).deliver_now

    # Activity log
    ActivityLog.log(
      business: appointment.business,
      action: "reminder_sent",
      description: "Recordatorio enviado a #{appointment.customer&.name}",
      actor_type: "system",
      resource: appointment
    )
  end
end
