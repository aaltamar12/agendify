# frozen_string_literal: true

# Publishes real-time events to NATS for browser consumption via WebSocket.
# This is a progressive enhancement — if NATS is unavailable, events are
# silently dropped and the frontend falls back to polling.
module Realtime
  class NatsPublisher
    def self.client
      @client ||= begin
        require "nats/client"
        nats = NATS::Client.new
        nats.connect(ENV.fetch("NATS_URL", "nats://localhost:4222"))
        nats
      end
    rescue StandardError => e
      Rails.logger.error("[NatsPublisher] Connection failed: #{e.message}")
      nil
    end

    # Publish event to a business channel.
    # Subject format: business.<id>.<event_name>
    def self.publish(business_id:, event:, data: {})
      return unless client

      subject = "business.#{business_id}.#{event}"
      payload = { event: event, data: data, timestamp: Time.current.iso8601 }.to_json
      client.publish(subject, payload)
      Rails.logger.info("[NatsPublisher] Published #{subject}")
    rescue StandardError => e
      Rails.logger.error("[NatsPublisher] Publish failed: #{e.message}")
    end

    # Reset connection (useful for tests or reconnection)
    def self.reset!
      @client&.close
    rescue StandardError
      # ignore
    ensure
      @client = nil
    end
  end
end
