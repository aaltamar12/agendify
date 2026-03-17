class AddUniqueSlotIndexToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_index :appointments,
              [:employee_id, :appointment_date, :start_time],
              unique: true,
              where: "status != 4",
              name: "idx_appointments_unique_slot"
  end
end
