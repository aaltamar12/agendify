class AddMetadataToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :metadata, :jsonb, default: {}
  end
end
