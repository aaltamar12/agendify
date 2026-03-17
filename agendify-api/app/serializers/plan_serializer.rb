# frozen_string_literal: true

class PlanSerializer < Blueprinter::Base
  identifier :id

  fields :name, :price_monthly, :max_employees, :max_services,
         :max_reservations_month, :max_customers,
         :ai_features, :ticket_digital, :advanced_reports,
         :brand_customization, :featured_listing, :priority_support,
         :created_at, :updated_at
end
