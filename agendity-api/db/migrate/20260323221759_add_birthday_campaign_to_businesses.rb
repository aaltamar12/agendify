class AddBirthdayCampaignToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :birthday_campaign_enabled, :boolean, default: false, null: false
    add_column :businesses, :birthday_discount_pct, :decimal, precision: 5, scale: 2, default: 10
    add_column :businesses, :birthday_discount_days_valid, :integer, default: 7
  end
end
