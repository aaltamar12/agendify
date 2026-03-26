# frozen_string_literal: true

module Notifications
  # Central service for sending notifications to end users (customers).
  # Agendity is the intermediary — always sends via all available channels
  # (email + WhatsApp). The business does NOT configure this.
  class MultiChannelService < BaseService
    def initialize(recipient:, template:, data:, business:)
      @recipient = recipient
      @template = template
      @data = data
      @business = business
    end

    def call
      results = {}

      channels.each do |channel|
        results[channel] = send_via(channel)
      rescue StandardError => e
        Rails.logger.error("[MultiChannelService] Error sending #{@template} via #{channel}: #{e.message}")
        results[channel] = false
      end

      success(results)
    end

    private

    def channels
      chs = [:email]
      chs << :whatsapp if @business.current_plan&.whatsapp_notifications?
      chs
    end

    def send_via(channel)
      case channel
      when :email
        Notifications::EmailChannel.deliver(recipient: @recipient, template: @template, data: @data)
      when :whatsapp
        Notifications::WhatsappChannel.deliver(recipient: @recipient, template: @template, data: @data)
      else
        false
      end
    end
  end
end
