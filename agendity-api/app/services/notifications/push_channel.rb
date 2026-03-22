# frozen_string_literal: true

module Notifications
  # Stub for push notifications — will be implemented with Capacitor/FCM.
  class PushChannel
    def self.deliver(recipient:, template:, data:)
      Rails.logger.info("[PushChannel] Not implemented yet, skipping #{template}")
      false
    end
  end
end
