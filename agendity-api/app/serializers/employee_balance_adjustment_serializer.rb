# frozen_string_literal: true

class EmployeeBalanceAdjustmentSerializer < Blueprinter::Base
  identifier :id

  fields :amount, :balance_before, :balance_after, :reason, :notes, :created_at

  field :employee_id do |adj, _options|
    adj.employee_id
  end

  field :employee_name do |adj, _options|
    adj.employee&.name
  end

  field :performed_by do |adj, _options|
    adj.performed_by_user&.name
  end
end
