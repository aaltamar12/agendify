# frozen_string_literal: true

class AppointmentSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :employee_id, :service_id, :customer_id,
         :price, :status, :ticket_code,
         :notes, :cancellation_reason, :cancelled_by,
         :created_at, :updated_at

  # Frontend expects "date", DB column is "appointment_date"
  field :date do |appointment, _options|
    appointment.appointment_date&.iso8601
  end

  field :start_time do |appointment, _options|
    appointment.start_time&.strftime("%H:%M")
  end

  field :end_time do |appointment, _options|
    appointment.end_time&.strftime("%H:%M")
  end

  view :detailed do
    association :service, blueprint: ServiceSerializer
    association :employee, blueprint: EmployeeSerializer, view: :minimal
    association :customer, blueprint: CustomerSerializer
    association :payment, blueprint: PaymentSerializer
  end

  view :calendar do
    excludes :business_id, :employee_id, :service_id, :customer_id,
             :price, :ticket_code, :notes,
             :cancellation_reason, :created_at, :updated_at

    field :service do |appointment, _options|
      { name: appointment.service&.name }
    end

    field :customer do |appointment, _options|
      { name: appointment.customer&.name }
    end

    field :employee do |appointment, _options|
      { name: appointment.employee&.name }
    end
  end
end
