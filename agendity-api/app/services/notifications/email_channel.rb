# frozen_string_literal: true

module Notifications
  # Sends notifications to customers via email using Action Mailer.
  class EmailChannel
    def self.deliver(recipient:, template:, data:)
      return false unless recipient.email.present?

      case template
      when :rating_request
        CustomerMailer.rating_request(recipient, data).deliver_now
      else
        Rails.logger.warn("[EmailChannel] Unknown template: #{template}")
        return false
      end

      true
    end
  end
end
