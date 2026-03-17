# frozen_string_literal: true

class CreateBusinessHours < ActiveRecord::Migration[8.0]
  def change
    create_table :business_hours do |t|
      t.references :business, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time    :open_time, null: false
      t.time    :close_time, null: false
      t.boolean :closed, default: false, null: false

      t.timestamps
    end

    add_index :business_hours, [:business_id, :day_of_week], unique: true
  end
end
