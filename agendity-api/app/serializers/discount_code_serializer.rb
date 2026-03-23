# frozen_string_literal: true

class DiscountCodeSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :code, :name, :discount_type, :discount_value,
         :max_uses, :current_uses, :valid_from, :valid_until,
         :active, :source, :customer_id, :created_at
end
