# frozen_string_literal: true

class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    create_table :businesses do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string  :name, null: false
      t.string  :slug, null: false
      t.integer :business_type, default: 0, null: false
      t.text    :description
      t.string  :phone
      t.string  :email
      t.string  :address
      t.string  :city
      t.string  :state
      t.string  :country, default: "CO", null: false
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.string  :logo_url
      t.string  :cover_image_url
      t.string  :instagram_url
      t.string  :facebook_url
      t.decimal :rating_average, precision: 3, scale: 2, default: 0.0, null: false
      t.integer :total_reviews, default: 0, null: false
      t.string  :timezone, default: "America/Bogota", null: false
      t.string  :currency, default: "COP", null: false
      t.text    :payment_instructions
      t.text    :bank_account_info
      t.string  :nequi_phone
      t.string  :daviplata_phone
      t.string  :bancolombia_account
      t.integer :cancellation_policy_pct, default: 0, null: false
      t.integer :cancellation_deadline_hours, default: 24, null: false
      t.datetime :trial_ends_at
      t.integer :status, default: 0, null: false
      t.boolean :onboarding_completed, default: false, null: false
      t.string  :primary_color
      t.string  :secondary_color

      t.timestamps
    end

    add_index :businesses, :slug, unique: true
    add_index :businesses, :status
    add_index :businesses, [:latitude, :longitude]
  end
end
