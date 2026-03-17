class AddCancellationFieldsToAppointmentsAndCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :cancelled_by, :string
    add_column :customers, :pending_penalty, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
