# frozen_string_literal: true

class CreateDynamicPricings < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_pricings do |t|
      t.references :business, null: false, foreign_key: true
      t.references :service, foreign_key: true # null = applies to all services
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :price_adjustment_type, default: 0  # 0=percentage, 1=fixed
      t.integer :adjustment_mode, default: 0         # 0=fixed, 1=progressive_asc, 2=progressive_desc
      t.decimal :adjustment_value, precision: 10, scale: 2       # for fixed mode
      t.decimal :adjustment_start_value, precision: 10, scale: 2 # for progressive mode
      t.decimal :adjustment_end_value, precision: 10, scale: 2   # for progressive mode
      t.integer :days_of_week, array: true, default: []          # empty = all days, [0,6] = sun+sat
      t.integer :status, default: 0          # 0=suggested, 1=active, 2=rejected, 3=expired
      t.string :suggested_by, default: "manual" # "system" | "manual"
      t.text :suggestion_reason              # AI explanation
      t.jsonb :analysis_data, default: {}    # data that generated the suggestion
      t.timestamps
    end
    add_index :dynamic_pricings, [:business_id, :status]
    add_index :dynamic_pricings, [:business_id, :start_date, :end_date]

    # Track dynamic pricing on appointments
    add_column :appointments, :dynamic_pricing_id, :bigint
    add_column :appointments, :original_price, :decimal, precision: 12, scale: 2
    add_foreign_key :appointments, :dynamic_pricings
  end
end
