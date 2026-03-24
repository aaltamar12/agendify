# frozen_string_literal: true

class CreateAdminNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_notifications do |t|
      t.string :title, null: false
      t.text :body
      t.string :notification_type
      t.string :link
      t.boolean :read, default: false, null: false
      t.string :icon
      t.timestamps
    end

    add_index :admin_notifications, :read
    add_index :admin_notifications, :created_at
  end
end
