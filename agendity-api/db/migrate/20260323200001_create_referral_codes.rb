# frozen_string_literal: true

class CreateReferralCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :referral_codes do |t|
      t.string :code, null: false
      t.string :referrer_name, null: false
      t.string :referrer_email
      t.string :referrer_phone
      t.decimal :commission_percentage, precision: 5, scale: 2, default: 10.0
      t.integer :status, default: 0, null: false
      t.text :notes
      t.timestamps
    end
    add_index :referral_codes, :code, unique: true
  end
end
