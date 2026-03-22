# frozen_string_literal: true

class EmployeePaymentSerializer < Blueprinter::Base
  identifier :id

  fields :employee_id, :appointments_count, :total_earned,
         :commission_pct, :commission_amount, :pending_from_previous,
         :total_owed, :amount_paid, :payment_method, :notes

  field :employee_name do |payment, _options|
    payment.employee&.name
  end

  field :proof_url do |payment, _options|
    if payment.proof.attached?
      Rails.application.routes.url_helpers.rails_blob_url(
        payment.proof,
        host: ENV.fetch("API_HOST", "http://localhost:3001")
      )
    end
  end

  field :remaining_debt do |payment, _options|
    [payment.total_owed - payment.amount_paid, 0].max.to_f
  end
end
