# frozen_string_literal: true

class CreateNotificationEventConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_event_configs do |t|
      t.string :event_key, null: false
      t.string :title, null: false
      t.string :body_template
      t.boolean :browser_notification, default: true, null: false
      t.boolean :sound_enabled, default: true, null: false
      t.boolean :in_app_notification, default: true, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :notification_event_configs, :event_key, unique: true
  end
end
