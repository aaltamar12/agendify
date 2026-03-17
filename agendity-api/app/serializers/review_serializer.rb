# frozen_string_literal: true

class ReviewSerializer < Blueprinter::Base
  identifier :id

  fields :appointment_id, :customer_id, :business_id, :employee_id,
         :rating, :comment, :created_at, :updated_at

  view :with_customer do
    association :customer, blueprint: CustomerSerializer
  end
end
