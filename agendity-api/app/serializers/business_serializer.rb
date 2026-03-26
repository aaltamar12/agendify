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
         :nequi_phone, :daviplata_phone, :bancolombia_account, :breb_key,
         :nit, :legal_representative_name, :legal_representative_document, :legal_representative_document_type, :independent,
         :birthday_campaign_enabled, :birthday_discount_pct, :birthday_discount_days_valid,
         :trial_ends_at, :virtual_business, :credits_enabled,
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

  # Serve cover from ActiveStorage, fallback to legacy cover_image_url column
  field :cover_url do |business, _options|
    if business.cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(
        business.cover_image,
        host: ENV.fetch("API_HOST", "http://localhost:3001")
      )
    else
      business.cover_image_url
    end
  end

  field :cover_source

  # Include current subscription with plan info
  association :current_subscription, blueprint: SubscriptionSerializer do |business, _options|
    business.subscriptions.current.order(end_date: :desc).first
  end

  # True when the business has an active plan with featured_listing
  field :featured do |business, _options|
    plan = business.subscriptions.where(status: :active).order(end_date: :desc).first&.plan
    plan&.featured_listing || false
  end

  # Returns the fraction of services covered by active dynamic pricings (0.0 to 1.0)
  # null service_id means "applies to all" → coverage = 1.0
  field :dynamic_pricing_coverage do |business, _options|
    active_pricings = business.dynamic_pricings.currently_active
    next 0.0 if active_pricings.empty?
    next 1.0 if active_pricings.where(service_id: nil).exists?

    total_services = business.services.where(active: true).count
    next 0.0 if total_services.zero?

    covered = active_pricings.where.not(service_id: nil).distinct.count(:service_id)
    (covered.to_f / total_services).round(2)
  end

  view :public do
    excludes :owner_id, :status, :onboarding_completed,
             :current_subscription, :cover_source,
             :cancellation_policy_pct, :cancellation_deadline_hours,
             :lunch_start_time, :lunch_end_time, :lunch_enabled,
             :slot_interval_minutes, :gap_between_appointments_minutes,
             :nequi_phone, :daviplata_phone, :bancolombia_account, :breb_key,
             :nit, :legal_representative_name,
             :birthday_campaign_enabled, :birthday_discount_pct, :birthday_discount_days_valid,
             :virtual_business, :credits_enabled,
             :created_at, :updated_at
  end

  # Minimal view for the public explore/directory page.
  # Only exposes what is needed to render a business card.
  view :explore do
    excludes :owner_id, :status, :onboarding_completed,
             :current_subscription, :cover_source,
             :cancellation_policy_pct, :cancellation_deadline_hours,
             :lunch_start_time, :lunch_end_time, :lunch_enabled,
             :slot_interval_minutes, :gap_between_appointments_minutes,
             :nequi_phone, :daviplata_phone, :bancolombia_account, :breb_key,
             :nit, :legal_representative_name, :legal_representative_document, :legal_representative_document_type, :independent,
             :primary_color, :secondary_color,
             :email, :timezone, :currency,
             :instagram_url, :facebook_url, :website_url, :google_maps_url,
             :birthday_campaign_enabled, :birthday_discount_pct, :birthday_discount_days_valid,
             :virtual_business, :credits_enabled,
             :created_at, :updated_at

    field :verified do |business, _options|
      plan = business.subscriptions.where(status: :active).order(end_date: :desc).first&.plan
      plan&.ai_features || false
    end
  end

  # Include full (decrypted) payment data — used for ticket pages and booking
  # confirmations where the end user needs to know where to pay.
  view :with_payment do
    excludes :owner_id, :status, :onboarding_completed,
             :current_subscription,
             :nit, :legal_representative_name,
             :created_at, :updated_at
  end

  view :minimal do
    excludes :owner_id, :description, :phone, :email, :address,
             :city, :state, :country, :latitude, :longitude,
             :logo_url, :timezone, :currency,
             :nequi_phone, :daviplata_phone, :bancolombia_account, :breb_key,
             :cancellation_policy_pct, :cancellation_deadline_hours,
             :lunch_start_time, :lunch_end_time, :lunch_enabled,
             :slot_interval_minutes, :gap_between_appointments_minutes,
             :status, :onboarding_completed,
             :primary_color, :secondary_color,
             :current_subscription,
             :created_at, :updated_at
  end
end
