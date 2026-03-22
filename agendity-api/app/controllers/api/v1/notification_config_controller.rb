# frozen_string_literal: true

module Api
  module V1
    # Public endpoint returning global notification event configurations.
    # No authentication required — config is the same for all clients.
    class NotificationConfigController < BaseController
      skip_before_action :authenticate_user!
      skip_before_action :require_business!
      skip_before_action :render_empty_for_admin_without_business!

      # GET /api/v1/notification_config
      def index
        configs = NotificationEventConfig.active.order(:event_key)
        render_success(configs.map { |c| serialize(c) })
      end

      private

      def serialize(config)
        {
          event_key: config.event_key,
          title: config.title,
          body_template: config.body_template,
          browser_notification: config.browser_notification,
          sound_enabled: config.sound_enabled,
          in_app_notification: config.in_app_notification
        }
      end
    end
  end
end
