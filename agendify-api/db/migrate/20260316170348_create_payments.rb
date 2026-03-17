# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :appointment, null: false, foreign_key: true
      t.integer :payment_method, default: 0, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string  :proof_image_url
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
