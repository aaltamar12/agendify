# frozen_string_literal: true

# Sends payment receipt emails to employees after a cash register close.
# For each EmployeePayment in the close, if the employee has an email,
# sends a payment receipt email.
class SendEmployeePaymentReceiptJob < ApplicationJob
  queue_as :mailers

  def perform(cash_register_close_id)
    close = CashRegisterClose.includes(employee_payments: :employee).find(cash_register_close_id)

    close.employee_payments.each do |payment|
      employee = payment.employee
      next unless employee.email.present?

      EmployeeMailer.payment_receipt(payment).deliver_now
    end
  end
end
