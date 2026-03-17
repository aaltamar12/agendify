# frozen_string_literal: true

# A review left by a customer for a business.
# Updates the business rating_average and total_reviews via counter cache.
class Review < ApplicationRecord
  include BusinessScoped

  # -- Associations --
  belongs_to :customer, optional: true

  # -- Validations --
  validates :rating, presence: true, numericality: { in: 1..5, only_integer: true }

  # -- Callbacks --
  after_create :update_business_rating
  after_destroy :update_business_rating

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[rating business_id customer_id created_at updated_at customer_name]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business customer]
  end

  private

  def update_business_rating
    avg = business.reviews.average(:rating).to_f.round(2)
    count = business.reviews.count
    business.update_columns(rating_average: avg, total_reviews: count)
  end
end
