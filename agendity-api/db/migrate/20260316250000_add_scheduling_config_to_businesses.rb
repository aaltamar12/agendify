# frozen_string_literal: true

class AddSchedulingConfigToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :lunch_start_time, :string, default: "12:00"
    add_column :businesses, :lunch_end_time, :string, default: "13:00"
    add_column :businesses, :lunch_enabled, :boolean, default: true
    add_column :businesses, :slot_interval_minutes, :integer, default: 30
    add_column :businesses, :gap_between_appointments_minutes, :integer, default: 0
  end
end
