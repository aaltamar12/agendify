# frozen_string_literal: true

module Api
  module V1
    # In-app notifications for the current business.
    # SRP: Only handles HTTP concerns for notification listing and read-state management.
    class NotificationsController < BaseController
      # GET /api/v1/notifications
      def index
        notifications = current_business.notifications.order(created_at: :desc)
        render_paginated(notifications, NotificationSerializer)
      end

      # POST /api/v1/notifications/:id/mark_read
      def mark_read
        notification = current_business.notifications.find(params[:id])
        notification.update!(read: true)
        render_success(NotificationSerializer.render_as_hash(notification))
      end

      # POST /api/v1/notifications/mark_all_read
      def mark_all_read
        current_business.notifications.unread.update_all(read: true)
        render_success({ message: "All notifications marked as read" })
      end

      # GET /api/v1/notifications/unread_count
      def unread_count
        count = current_business.notifications.unread.count
        render_success({ unread_count: count })
      end
    end
  end
end
