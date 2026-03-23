# frozen_string_literal: true

class CreateBusinessGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :business_goals do |t|
      t.references :business, null: false, foreign_key: true
      t.string :goal_type, null: false        # break_even, monthly_sales, daily_average, custom
      t.string :name                           # "Meta de ventas marzo"
      t.decimal :target_value, precision: 12, scale: 2, null: false
      t.string :period, default: "monthly"     # monthly, weekly
      t.decimal :fixed_costs, precision: 12, scale: 2  # for break_even: rent, utilities, etc.
      t.jsonb :metadata, default: {}
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :business_goals, [:business_id, :goal_type]
  end
end
