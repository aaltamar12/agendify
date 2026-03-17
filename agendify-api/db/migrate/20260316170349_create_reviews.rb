# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :business, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.string  :customer_name
      t.integer :rating, null: false
      t.text    :comment

      t.timestamps
    end
  end
end
