class AddPaymentTypeToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :payment_type, :string, default: "none", null: false
    add_column :employees, :fixed_daily_pay, :decimal, precision: 12, scale: 2, default: 0
  end
end
