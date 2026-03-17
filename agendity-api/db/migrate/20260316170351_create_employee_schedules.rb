# frozen_string_literal: true

class CreateEmployeeSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_schedules do |t|
      t.references :employee, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time    :start_time, null: false
      t.time    :end_time, null: false

      t.timestamps
    end

    add_index :employee_schedules, [:employee_id, :day_of_week], unique: true
  end
end
