# frozen_string_literal: true

class CreateCreditSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_accounts do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.decimal :balance, precision: 12, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :credit_accounts, [:customer_id, :business_id], unique: true

    create_table :credit_transactions do |t|
      t.references :credit_account, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :transaction_type, null: false
      t.string :description
      t.references :appointment, foreign_key: true
      t.references :performed_by_user, foreign_key: { to_table: :users }
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :credit_transactions, :transaction_type

    # Business cashback config
    add_column :businesses, :cashback_enabled, :boolean, default: false
    add_column :businesses, :cashback_percentage, :decimal, precision: 5, scale: 2, default: 0
    add_column :businesses, :cancellation_refund_as_credit, :boolean, default: true

    # Track credits applied on appointments
    add_column :appointments, :credits_applied, :decimal, precision: 12, scale: 2, default: 0
  end
end
