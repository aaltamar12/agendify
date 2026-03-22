# frozen_string_literal: true

class AddCustomerNotificationChannelsToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :customer_notification_channels, :jsonb, default: { "email" => true, "whatsapp" => false, "push" => false }
  end
end
