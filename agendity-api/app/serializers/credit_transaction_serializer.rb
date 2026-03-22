# frozen_string_literal: true

class CreditTransactionSerializer < Blueprinter::Base
  identifier :id

  fields :amount, :transaction_type, :description, :metadata, :created_at

  field :appointment_id do |tx, _options|
    tx.appointment_id
  end

  field :performed_by do |tx, _options|
    tx.performed_by_user&.name
  end
end
