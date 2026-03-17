# frozen_string_literal: true

class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :business, null: false, foreign_key: true
      t.string :action, null: false
      t.string :actor_type
      t.string :actor_name
      t.text :description
      t.string :resource_type
      t.bigint :resource_id
      t.string :ip_address
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :activity_logs, [:business_id, :created_at]
    add_index :activity_logs, [:resource_type, :resource_id]
  end
end
