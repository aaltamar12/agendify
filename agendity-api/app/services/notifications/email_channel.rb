# frozen_string_literal: true

module Notifications
  # Sends notifications to customers via email using Action Mailer.
  class EmailChannel
    def self.deliver(recipient:, template:, data:)
      return false unless recipient.email.present?

      case template
      when :rating_request
        CustomerMailer.rating_request(recipient, data).deliver_now
      when :booking_confirmed
        AppointmentMailer.booking_confirmed(data[:appointment]).deliver_now
      when :appointment_reminder
        AppointmentMailer.reminder(data[:appointment]).deliver_now
      when :appointment_reminder_30min
        AppointmentMailer.reminder_30min(data[:appointment]).deliver_now
      when :booking_cancelled
        AppointmentMailer.booking_cancelled_to_customer(data[:appointment]).deliver_now
      when :payment_reminder
        AppointmentMailer.payment_reminder(data[:appointment]).deliver_now
      when :payment_rejected
        AppointmentMailer.payment_rejected(data[:appointment], data[:reason]).deliver_now
      when :birthday_greeting
        CustomerMailer.birthday_greeting(recipient, data).deliver_now
      else
        Rails.logger.warn("[EmailChannel] Unknown template: #{template}")
        return false
      end

      true
    end
  end
end
