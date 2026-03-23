# frozen_string_literal: true

class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.references :referral_code, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.references :subscription, foreign_key: true
      t.integer :status, default: 0, null: false
      t.decimal :commission_amount, precision: 10, scale: 2
      t.date :activated_at
      t.date :paid_at
      t.text :notes
      t.timestamps
    end
    add_index :referrals, [:referral_code_id, :business_id], unique: true
  end
end
