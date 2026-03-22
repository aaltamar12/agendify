# frozen_string_literal: true

class CreditAccountSerializer < Blueprinter::Base
  identifier :id

  fields :customer_id, :business_id, :balance, :created_at, :updated_at

  field :customer_name do |account, _options|
    account.customer&.name
  end

  field :customer_email do |account, _options|
    account.customer&.email
  end
end
