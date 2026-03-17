# frozen_string_literal: true

# Operating hours for a business on a specific day of the week.
class BusinessHour < ApplicationRecord
  include BusinessScoped

  # -- Validations --
  validates :day_of_week, presence: true, numericality: { in: 0..6, only_integer: true }
  validates :day_of_week, uniqueness: { scope: :business_id }
  validates :open_time, presence: true
  validates :close_time, presence: true

  # -- Scopes --
  scope :open_days, -> { where(closed: false) }
  scope :for_day, ->(day) { find_by(day_of_week: day) }
end
