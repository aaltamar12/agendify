# frozen_string_literal: true

class SubscriptionSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :plan_id, :start_date, :end_date,
         :status, :created_at, :updated_at

  association :plan, blueprint: PlanSerializer
end
