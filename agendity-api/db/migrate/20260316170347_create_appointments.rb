# frozen_string_literal: true

class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :business, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.date     :appointment_date, null: false
      t.time     :start_time, null: false
      t.time     :end_time, null: false
      t.decimal  :price, precision: 10, scale: 2, null: false
      t.integer  :status, default: 0, null: false
      t.string   :ticket_code
      t.string   :ticket_url
      t.text     :notes
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :appointments, :ticket_code, unique: true
    add_index :appointments, [:business_id, :appointment_date, :status], name: "idx_appointments_biz_date_status"
    add_index :appointments, [:employee_id, :appointment_date], name: "idx_appointments_employee_date"
  end
end
