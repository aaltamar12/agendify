# frozen_string_literal: true

class AdBanner < ApplicationRecord
  has_one_attached :image

  # --- Validations ---
  validates :name, presence: true
  validates :placement, presence: true

  # --- Scopes ---
  scope :active, -> { where(active: true) }
  scope :for_placement, ->(placement) { where(placement: placement) }
  scope :current, -> {
    today = Date.current
    where("(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)", today, today)
  }

  # --- Ransack support for ActiveAdmin ---
  def self.ransackable_attributes(_auth_object = nil)
    %w[name placement active priority start_date end_date impressions_count clicks_count created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[image_attachment image_blob]
  end

  # --- Helpers ---

  # Returns the display image URL: attached image takes priority, falls back to image_url field
  def display_image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
    else
      image_url
    end
  end

  # Click-through rate as a percentage
  def ctr
    return 0.0 if impressions_count.zero?

    (clicks_count.to_f / impressions_count * 100).round(2)
  end
end
