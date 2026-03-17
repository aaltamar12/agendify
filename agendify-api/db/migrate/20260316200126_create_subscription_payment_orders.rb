# frozen_string_literal: true

class CreateSubscriptionPaymentOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_payment_orders do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :due_date, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :status, default: "pending"
      t.text :notes
      t.timestamps
    end

    add_index :subscription_payment_orders, %i[business_id status]
    add_index :subscription_payment_orders, :due_date
  end
end
