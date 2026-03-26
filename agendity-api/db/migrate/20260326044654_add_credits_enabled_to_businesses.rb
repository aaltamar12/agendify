class AddCreditsEnabledToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :credits_enabled, :boolean, default: true, null: false
  end
end
