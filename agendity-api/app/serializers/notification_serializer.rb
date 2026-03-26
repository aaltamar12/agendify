# frozen_string_literal: true

class NotificationSerializer < Blueprinter::Base
  identifier :id

  fields :title, :body, :notification_type, :link, :read, :metadata, :created_at
end
