# frozen_string_literal: true

class AddReferralFieldsToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_reference :businesses, :referral_code, foreign_key: true, null: true
    add_column :businesses, :trial_alert_stage, :integer, default: 0, null: false
  end
end
