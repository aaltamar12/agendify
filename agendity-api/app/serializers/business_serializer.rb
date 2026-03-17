# frozen_string_literal: true

class BusinessSerializer < Blueprinter::Base
  identifier :id

  fields :owner_id, :name, :slug, :business_type, :description,
         :phone, :email, :address, :city, :state, :country,
         :latitude, :longitude,
         :timezone, :currency, :status, :onboarding_completed,
         :primary_color, :secondary_color,
         :instagram_url, :facebook_url, :website_url, :google_maps_url,
         :rating_average, :total_reviews,
         :cancellation_policy_pct, :cancellation_deadline_hours,
         :lunch_start_time, :lunch_end_time, :lunch_enabled,
         :slot_interval_minutes, :gap_between_appointments_minutes,
         :nequi_phone, :daviplata_phone, :bancolombia_account,
         :created_at, :updated_at

  # Serve logo from ActiveStorage attachment, fallback to legacy logo_url column
  field :logo_url do |business, _options|
    if business.logo.attached?
      Rails.application.routes.url_helpers.rails_blob_url(
        business.logo,
        host: ENV.fetch("API_HOST", "http://localhost:3001")
      )
    else
      business.read_attribute(:logo_url)
    end
  end

  # Frontend expects cover_url, DB column is cover_image_url
  field :cover_url do |business, _options|
    business.cover_image_url
  end

  # Include current subscription with plan info
  association :current_subscription, blueprint: SubscriptionSerializer do |business, _options|
    business.subscriptions.current.order(end_date: :desc).first
  end

  # True when the business has an active plan with featured_listing
  field :featured do |business, _options|
    plan = business.subscriptions.where(status: :active).order(end_date: :desc).first&.plan
    plan&.featured_listing || false
  end

  view :public do
    excludes :owner_id, :status, :onboarding_completed,
             :current_subscription,
             :cancellation_policy_pct, :cancellation_deadline_hours,
             :lunch_start_time, :lunch_end_time, :lunch_enabled,
             :slot_interval_minutes, :gap_between_appointments_minutes,
             :nequi_phone, :daviplata_phone, :bancolombia_account,
             :created_at, :updated_at
  end

  # Include full (decrypted) payment data — used for ticket pages and booking
  # confirmations where the end user needs to know where to pay.
  view :with_payment do
    excludes :owner_id, :status, :onboarding_completed,
             :current_subscription,
             :created_at, :updated_at
  end

  view :minimal do
    excludes :owner_id, :description, :phone, :email, :address,
             :city, :state, :country, :latitude, :longitude,
             :logo_url, :timezone, :currency,
             :nequi_phone, :daviplata_phone, :bancolombia_account,
             :cancellation_policy_pct, :cancellation_deadline_hours,
             :lunch_start_time, :lunch_end_time, :lunch_enabled,
             :slot_interval_minutes, :gap_between_appointments_minutes,
             :status, :onboarding_completed,
             :primary_color, :secondary_color,
             :current_subscription,
             :created_at, :updated_at
  end
end
