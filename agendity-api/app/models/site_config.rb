# frozen_string_literal: true

# Key-value store for global platform settings (payment info, contact data, etc.).
# Managed via ActiveAdmin.
class SiteConfig < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value, description: nil)
    config = find_or_initialize_by(key: key)
    config.update!(value: value, description: description || config.description)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[key value description created_at]
  end
end
