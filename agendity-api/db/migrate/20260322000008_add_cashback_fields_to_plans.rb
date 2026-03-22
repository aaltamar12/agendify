# frozen_string_literal: true

class AddCashbackFieldsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :cashback_enabled, :boolean, default: false, null: false
    add_column :plans, :cashback_percentage, :decimal, precision: 5, scale: 2, default: 0, null: false
  end
end
