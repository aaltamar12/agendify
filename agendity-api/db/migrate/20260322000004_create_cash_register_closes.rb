# frozen_string_literal: true

class CreateCashRegisterCloses < ActiveRecord::Migration[8.0]
  def change
    create_table :cash_register_closes do |t|
      t.references :business, null: false, foreign_key: true
      t.references :closed_by_user, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.datetime :closed_at
      t.decimal :total_revenue, precision: 12, scale: 2, default: 0
      t.decimal :total_tips, precision: 12, scale: 2, default: 0
      t.integer :total_appointments, default: 0
      t.text :notes
      t.integer :status, default: 0
      t.timestamps
    end
    add_index :cash_register_closes, [:business_id, :date], unique: true

    create_table :employee_payments do |t|
      t.references :cash_register_close, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.integer :appointments_count, default: 0
      t.decimal :total_earned, precision: 12, scale: 2, default: 0
      t.decimal :commission_pct, precision: 5, scale: 2, default: 0
      t.decimal :commission_amount, precision: 12, scale: 2, default: 0
      t.decimal :amount_paid, precision: 12, scale: 2, default: 0
      t.integer :payment_method, default: 0
      t.text :notes
      t.timestamps
    end
  end
end
