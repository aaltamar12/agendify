# frozen_string_literal: true

module Notifications
  # Sends notifications to customers via WhatsApp Business API.
  # Currently a stub — will be implemented when WhatsApp API is configured.
  class WhatsAppChannel
    def self.deliver(recipient:, template:, data:)
      api_token = ENV["WHATSAPP_API_TOKEN"]
      phone_id = ENV["WHATSAPP_PHONE_NUMBER_ID"]

      unless api_token.present? && phone_id.present?
        Rails.logger.info("[WhatsAppChannel] Not configured, skipping #{template} for #{recipient.phone}")
        return false
      end

      # Supported templates:
      #   :rating_request        (MARKETING) — post-service rating
      #   :booking_confirmed     (UTILITY)   — payment approved, ticket ready
      #   :appointment_reminder  (UTILITY)   — 24h before appointment
      #   :booking_cancelled     (UTILITY)   — appointment cancelled
      #   :payment_reminder      (UTILITY)   — pending payment reminder
      #   :payment_rejected      (UTILITY)   — proof of payment rejected
      #   :birthday_greeting     (MARKETING) — birthday greeting with discount code
      # Note: cashback_credited goes via email only (not WhatsApp) to save conversation costs.
      # Cashback info is appended to the booking_confirmed WhatsApp template instead.
      # TODO: Implement WhatsApp Business API integration
      Rails.logger.info("[WhatsAppChannel] Would send #{template} to #{recipient.phone}")
      false
    end
  end
end
