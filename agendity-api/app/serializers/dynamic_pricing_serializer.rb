# frozen_string_literal: true

class DynamicPricingSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :service_id, :name, :start_date, :end_date,
         :price_adjustment_type, :adjustment_mode,
         :adjustment_value, :adjustment_start_value, :adjustment_end_value,
         :days_of_week, :status, :suggested_by, :suggestion_reason,
         :analysis_data, :created_at, :updated_at

  field :service_name do |dp, _options|
    dp.service&.name
  end
end
