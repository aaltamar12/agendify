# frozen_string_literal: true

class EmployeeSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :user_id, :name, :phone, :email,
         :bio, :active, :commission_percentage,
         :created_at, :updated_at

  # Frontend expects avatar_url — prefer ActiveStorage avatar, fallback to legacy photo_url
  field :avatar_url do |employee, _options|
    if employee.avatar.attached?
      Rails.application.routes.url_helpers.url_for(employee.avatar)
    else
      employee.photo_url
    end
  end

  # IDs of services this employee can perform
  field :service_ids do |employee, _options|
    employee.employee_services.pluck(:service_id)
  end

  view :with_services do
    association :services, blueprint: ServiceSerializer
  end

  view :minimal do
    excludes :business_id, :user_id, :phone, :email, :bio,
             :commission_percentage,
             :created_at, :updated_at
  end
end
