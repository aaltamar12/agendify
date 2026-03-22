# frozen_string_literal: true

class CashRegisterCloseSerializer < Blueprinter::Base
  identifier :id

  fields :date, :closed_at, :total_revenue, :total_tips,
         :total_appointments, :notes, :status, :created_at

  view :with_payments do
    association :employee_payments, blueprint: EmployeePaymentSerializer
  end

  view :detailed do
    association :employee_payments, blueprint: EmployeePaymentSerializer
  end
end
