# frozen_string_literal: true

class AdminNotification < ApplicationRecord
  validates :title, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def mark_read!
    update!(read: true)
  end

  def self.mark_all_read!
    unread.update_all(read: true)
  end

  def self.notify!(title:, body: nil, notification_type: nil, link: nil, icon: nil)
    create!(title: title, body: body, notification_type: notification_type, link: link, icon: icon)
  end
end
