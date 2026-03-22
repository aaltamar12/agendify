# frozen_string_literal: true

module Notifications
  # Central service for sending notifications to end users (customers)
  # across multiple channels (email, WhatsApp, push).
  class MultiChannelService < BaseService
    def initialize(recipient:, template:, data:, channels: nil)
      @recipient = recipient
      @template = template
      @data = data
      @channels = channels || [:email]
    end

    def call
      results = {}

      @channels.each do |channel|
        results[channel] = send_via(channel)
      rescue StandardError => e
        Rails.logger.error("[MultiChannelService] Error sending #{@template} via #{channel}: #{e.message}")
        results[channel] = false
      end

      success(results)
    end

    private

    def send_via(channel)
      case channel.to_sym
      when :email
        Notifications::EmailChannel.deliver(recipient: @recipient, template: @template, data: @data)
      when :whatsapp
        Notifications::WhatsAppChannel.deliver(recipient: @recipient, template: @template, data: @data)
      when :push
        Notifications::PushChannel.deliver(recipient: @recipient, template: @template, data: @data)
      else
        Rails.logger.warn("[MultiChannelService] Unknown channel: #{channel}")
        false
      end
    end
  end
end
