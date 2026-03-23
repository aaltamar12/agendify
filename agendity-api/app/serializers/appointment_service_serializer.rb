# frozen_string_literal: true

class AppointmentServiceSerializer < Blueprinter::Base
  identifier :id

  fields :service_id, :price, :duration_minutes

  field :service_name do |as, _options|
    as.service&.name
  end
end
