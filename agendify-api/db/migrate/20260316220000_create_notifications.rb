# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :business, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :notification_type, null: false
      t.string :link
      t.boolean :read, default: false

      t.timestamps
    end

    add_index :notifications, [:business_id, :read]
    add_index :notifications, [:business_id, :created_at]
  end
end
