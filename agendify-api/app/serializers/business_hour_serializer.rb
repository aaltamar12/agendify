# frozen_string_literal: true

class BusinessHourSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :day_of_week, :closed,
         :created_at, :updated_at

  field :open_time do |business_hour, _options|
    business_hour.open_time&.strftime("%H:%M")
  end

  field :close_time do |business_hour, _options|
    business_hour.close_time&.strftime("%H:%M")
  end
end
