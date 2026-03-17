# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :business, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.date    :start_date, null: false
      t.date    :end_date, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
