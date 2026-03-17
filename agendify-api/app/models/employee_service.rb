# frozen_string_literal: true

# Join table linking employees to the services they can perform.
class EmployeeService < ApplicationRecord
  # -- Associations --
  belongs_to :employee
  belongs_to :service

  # -- Validations --
  validates :employee_id, uniqueness: { scope: :service_id }
end
