# frozen_string_literal: true

class CreateRequestLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :request_logs do |t|
      t.references :business, foreign_key: true, null: true
      t.string :method, null: false
      t.string :path, null: false
      t.string :controller_action
      t.integer :status_code
      t.float :duration_ms
      t.string :ip_address
      t.string :user_agent
      t.jsonb :request_params, default: {}
      t.jsonb :response_body, default: {}
      t.text :error_message
      t.text :error_backtrace
      t.string :request_id
      t.string :resource_type
      t.bigint :resource_id
      t.timestamps
    end

    add_index :request_logs, [:business_id, :created_at]
    add_index :request_logs, :request_id
    add_index :request_logs, [:resource_type, :resource_id]
    add_index :request_logs, :status_code
    add_index :request_logs, :created_at
  end
end
