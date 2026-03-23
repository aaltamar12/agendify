# frozen_string_literal: true

class CreateAppointmentServices < ActiveRecord::Migration[8.0]
  def change
    create_table :appointment_services do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.decimal :price, precision: 12, scale: 2
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :appointment_services, [:appointment_id, :service_id], unique: true
  end
end
