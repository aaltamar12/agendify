# frozen_string_literal: true

# Finds all confirmed appointments happening tomorrow and enqueues
# a SendReminderJob for each one.
class AppointmentReminderSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    tomorrow = Date.tomorrow

    Appointment.confirmed.on_date(tomorrow).find_each do |appointment|
      SendReminderJob.perform_later(appointment.id)
    end
  end
end
