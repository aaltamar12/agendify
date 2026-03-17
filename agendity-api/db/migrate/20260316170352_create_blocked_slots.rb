# frozen_string_literal: true

class CreateBlockedSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_slots do |t|
      t.references :business, null: false, foreign_key: true
      t.references :employee, foreign_key: true
      t.date   :date, null: false
      t.time   :start_time, null: false
      t.time   :end_time, null: false
      t.string :reason

      t.timestamps
    end

    add_index :blocked_slots, [:business_id, :date], name: "idx_blocked_slots_biz_date"
  end
end
