# frozen_string_literal: true

class EmployeePaymentSerializer < Blueprinter::Base
  identifier :id

  fields :employee_id, :appointments_count, :total_earned,
         :commission_pct, :commission_amount, :amount_paid,
         :payment_method, :notes

  field :employee_name do |payment, _options|
    payment.employee&.name
  end
end
