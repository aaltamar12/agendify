# frozen_string_literal: true

class AddPriceMonthlyUsdToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :price_monthly_usd, :decimal, precision: 8, scale: 2
  end
end
