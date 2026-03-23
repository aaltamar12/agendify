class AddDiscountFieldsToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_reference :appointments, :discount_code, foreign_key: true, null: true
    add_column :appointments, :discount_amount, :decimal, precision: 10, scale: 2, default: 0
  end
end
