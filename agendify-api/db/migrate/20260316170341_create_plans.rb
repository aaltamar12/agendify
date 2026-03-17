# frozen_string_literal: true

class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string  :name, null: false
      t.decimal :price_monthly, precision: 10, scale: 2, null: false
      t.integer :max_employees
      t.integer :max_services
      t.integer :max_reservations_month
      t.integer :max_customers
      t.boolean :ai_features, default: false, null: false
      t.boolean :ticket_digital, default: false, null: false
      t.boolean :advanced_reports, default: false, null: false
      t.boolean :brand_customization, default: false, null: false
      t.boolean :featured_listing, default: false, null: false
      t.boolean :priority_support, default: false, null: false

      t.timestamps
    end
  end
end
