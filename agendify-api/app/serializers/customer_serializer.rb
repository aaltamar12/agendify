# frozen_string_literal: true

class CustomerSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :name, :phone, :email, :notes,
         :created_at, :updated_at

  # Frontend expects total_visits
  field :total_visits do |customer, _options|
    customer.appointments.count
  end

  # Frontend expects last_visit_at
  field :last_visit_at do |customer, _options|
    customer.appointments.where(status: :completed).maximum(:appointment_date)&.iso8601
  end

  view :with_appointments do
    association :appointments, blueprint: AppointmentSerializer
  end
end
