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

      # TODO: Implement WhatsApp Business API integration
      Rails.logger.info("[WhatsAppChannel] Would send #{template} to #{recipient.phone}")
      false
    end
  end
end
