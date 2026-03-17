# frozen_string_literal: true

# A manual block in the schedule (lunch break, vacation, etc.).
# If employee_id is nil, the block applies to the entire business.
class BlockedSlot < ApplicationRecord
  include BusinessScoped

  # -- Associations --
  belongs_to :employee, optional: true

  # -- Validations --
  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  # -- Scopes --
  scope :on_date, ->(date) { where(date: date) }
  scope :for_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :business_wide, -> { where(employee_id: nil) }
end
