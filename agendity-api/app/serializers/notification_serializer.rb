# frozen_string_literal: true

class NotificationSerializer < Blueprinter::Base
  identifier :id

  fields :title, :body, :notification_type, :link, :read, :created_at
end
