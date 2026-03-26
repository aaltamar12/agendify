# frozen_string_literal: true

module CashRegister
  # Generates a PDF payment receipt for an EmployeePayment using Grover.
  # Returns the PDF binary data on success.
  class GeneratePaymentReceiptService < BaseService
    def initialize(employee_payment:)
      @employee_payment = employee_payment
      @employee = employee_payment.employee
      @close = employee_payment.cash_register_close
      @business = @close.business
    end

    def call
      html = ApplicationController.render(
        template: "employee_mailer/payment_receipt_pdf",
        layout: "pdf",
        assigns: {
          employee_payment: @employee_payment,
          employee: @employee,
          close: @close,
          business: @business,
          date: @close.date
        }
      )

      pdf = Grover.new(html, format: "A4", print_background: true).to_pdf
      success(pdf)
    rescue StandardError => e
      failure("Error generating PDF: #{e.message}", code: "PDF_GENERATION_ERROR")
    end
  end
end
