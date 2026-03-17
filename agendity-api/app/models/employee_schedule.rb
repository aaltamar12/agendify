# frozen_string_literal: true

# Working hours for an employee on a specific day of the week.
class EmployeeSchedule < ApplicationRecord
  # -- Associations --
  belongs_to :employee

  # -- Validations --
  validates :day_of_week, presence: true, numericality: { in: 0..6, only_integer: true }
  validates :day_of_week, uniqueness: { scope: :employee_id }
  validates :start_time, presence: true
  validates :end_time, presence: true
end
