# frozen_string_literal: true

class AddCheckoutFieldsToSubscriptionPaymentOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :subscription_payment_orders, :plan, foreign_key: true, null: true
    add_column :subscription_payment_orders, :proof_submitted_at, :datetime
    add_column :subscription_payment_orders, :reviewed_by, :string
    add_column :subscription_payment_orders, :reviewed_at, :datetime
    change_column_null :subscription_payment_orders, :subscription_id, true
  end
end
