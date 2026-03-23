# frozen_string_literal: true

# A registered business on the platform (barbershop, salon, etc.).
# Uses friendly_id for slug-based URLs and Geocoder for geolocation.
class Business < ApplicationRecord
  include PlanEnforcement

  extend FriendlyId

  friendly_id :name, use: :slugged

  geocoded_by :full_address
  after_validation :geocode, if: ->(b) { b.address_changed? || b.city_changed? }

  # -- Encryption (sensitive payment data at rest) --
  # deterministic: true allows querying (find_by, where) on these fields
  encrypts :nequi_phone, deterministic: true
  encrypts :daviplata_phone, deterministic: true
  encrypts :bancolombia_account, deterministic: true

  # -- Enums --
  enum :business_type, { barbershop: 0, salon: 1, spa: 2, nails: 3, other: 4 }
  enum :status, { active: 0, suspended: 1, inactive: 2 }

  # -- Attachments --
  include AttachmentValidations
  has_one_attached :logo
  has_one_attached :cover_image
  validate_attachment :logo, max_size: 5.megabytes
  validate_attachment :cover_image, max_size: 5.megabytes

  # -- Associations --
  belongs_to :owner, class_name: "User", inverse_of: :businesses
  belongs_to :referral_code, optional: true
  has_one :referral, dependent: :destroy

  has_many :employees, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :business_hours, dependent: :destroy
  has_many :blocked_slots, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subscription_payment_orders, dependent: :destroy
  has_many :cash_register_closes, dependent: :destroy
  has_many :credit_accounts, dependent: :destroy
  has_many :dynamic_pricings, dependent: :destroy
  has_many :employee_balance_adjustments, dependent: :destroy
  has_many :business_goals, dependent: :destroy
  has_many :discount_codes, dependent: :destroy

  # -- Validations --
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :business_type, presence: true
  validates :status, presence: true
  validates :cancellation_policy_pct, numericality: { in: 0..100 }
  validates :cancellation_deadline_hours, numericality: { greater_than_or_equal_to: 0 }
  validates :slot_interval_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :gap_between_appointments_minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rating_average, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  # -- Callbacks --
  before_save :extract_coords_from_google_maps_url, if: :google_maps_url_changed?

  # -- Scopes --
  scope :active, -> { where(status: :active) }
  scope :independent, -> { where(independent: true) }
  scope :establishments, -> { where(independent: false) }
  scope :in_trial, -> { where("trial_ends_at > ?", Time.current) }
  scope :trial_expiring_in, ->(days) {
    target = Date.current + days
    where("trial_ends_at::date = ?", target).where("trial_ends_at IS NOT NULL")
  }
  scope :trial_expired_since, ->(days) {
    target = Date.current - days
    where("trial_ends_at::date = ?", target).where("trial_ends_at IS NOT NULL")
  }
  scope :nearby, ->(lat, lng, radius_km = 10) { near([lat, lng], radius_km, units: :km) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug business_type status city onboarding_completed independent created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[owner employees services customers appointments reviews subscriptions]
  end

  private

  def full_address
    [address, city, country].compact.join(", ")
  end

  # Extract lat/lng from Google Maps URL patterns:
  # https://www.google.com/maps/place/.../@10.9878,-74.7889,17z/...
  # https://maps.google.com/?q=10.9878,-74.7889
  # https://goo.gl/maps/... (won't extract, but URL itself is useful)
  # https://maps.app.goo.gl/...
  def extract_coords_from_google_maps_url
    return if google_maps_url.blank?

    url = resolve_short_url(google_maps_url.strip)

    extract_coords_from_url(url)
  end

  # Follow redirects on short URLs (goo.gl, maps.app.goo.gl)
  def resolve_short_url(url)
    return url unless url.match?(/goo\.gl|bit\.ly/)

    require "net/http"
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.head(uri.request_uri)
    end

    if response.is_a?(Net::HTTPRedirection) && response["location"]
      resolved = response["location"]
      # Some redirects are relative or chain — follow one more if needed
      if resolved.match?(/goo\.gl|maps\.app/)
        resolve_short_url(resolved)
      else
        resolved
      end
    else
      url
    end
  rescue StandardError
    url
  end

  def extract_coords_from_url(url)
    # Pattern 1: /@lat,lng in URL
    if url =~ /@(-?\d+\.?\d*),(-?\d+\.?\d*)/
      self.latitude = ::Regexp.last_match(1).to_f
      self.longitude = ::Regexp.last_match(2).to_f
      return
    end

    # Pattern 2: /search/lat,lng or ?q=lat,lng
    if url =~ /\/search\/(-?\d+\.?\d*),\+?(-?\d+\.?\d*)/
      self.latitude = ::Regexp.last_match(1).to_f
      self.longitude = ::Regexp.last_match(2).to_f
      return
    end

    # Pattern 3: ?q=lat,lng
    if url =~ /[?&]q=(-?\d+\.?\d*),\+?(-?\d+\.?\d*)/
      self.latitude = ::Regexp.last_match(1).to_f
      self.longitude = ::Regexp.last_match(2).to_f
      return
    end

    # Pattern 3: !3dLAT!4dLNG (Google Maps data format)
    if url =~ /!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)/
      self.latitude = ::Regexp.last_match(1).to_f
      self.longitude = ::Regexp.last_match(2).to_f
      return
    end

    # Pattern 4: /place/lat,lng
    if url =~ /\/place\/(-?\d+\.?\d*),(-?\d+\.?\d*)/
      self.latitude = ::Regexp.last_match(1).to_f
      self.longitude = ::Regexp.last_match(2).to_f
    end
  end
end
