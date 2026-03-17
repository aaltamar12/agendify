# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name
      t.string :phone
      t.string :email

      t.timestamps
    end

    add_index :customers, [:business_id, :email], unique: true
  end
end
