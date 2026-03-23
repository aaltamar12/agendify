# frozen_string_literal: true

# Tracks which expiry alert stage has been sent for a subscription
# to prevent duplicate notifications.
# Stages: 0 = none, 1 = 5-day warning, 2 = expiration day, 3 = grace period (suspended)
class AddExpiryAlertStageToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :expiry_alert_stage, :integer, default: 0, null: false
  end
end
