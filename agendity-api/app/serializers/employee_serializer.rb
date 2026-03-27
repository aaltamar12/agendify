# frozen_string_literal: true

class EmployeeSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :user_id, :name, :phone, :email,
         :bio, :active, :commission_percentage,
         :payment_type, :fixed_daily_pay,
         :document_number, :document_type, :fiscal_address,
         :rating_average, :total_reviews,
         :created_at, :updated_at

  # Frontend expects avatar_url — prefer ActiveStorage avatar, fallback to legacy photo_url
  field :avatar_url do |employee, _options|
    if employee.avatar.attached?
      Rails.application.routes.url_helpers.url_for(employee.avatar)
    else
      employee.photo_url
    end
  end

  field :has_account do |employee, _options|
    employee.user_id.present?
  end

  # Score: rating (60%) + punctuality (40%)
  field :score do |employee, _options|
    result = Employees::ScoreService.call(employee: employee)
    result.success? ? result.data[:overall] : nil
  end

  field :rating_avg do |employee, _options|
    Review.joins(:appointment)
          .where(appointments: { employee_id: employee.id })
          .average(:rating)&.round(1).to_f || 0
  end

  # IDs of services this employee can perform
  field :service_ids do |employee, _options|
    employee.employee_services.pluck(:service_id)
  end

  # Work schedules for the employee form
  field :schedules do |employee, _options|
    employee.employee_schedules.order(:day_of_week).map do |s|
      { day_of_week: s.day_of_week, start_time: s.start_time, end_time: s.end_time, active: true }
    end
  end

  view :with_services do
    association :services, blueprint: ServiceSerializer
  end

  view :minimal do
    excludes :business_id, :user_id, :phone, :email, :bio,
             :commission_percentage, :score, :rating_avg,
             :document_number, :document_type, :fiscal_address,
             :created_at, :updated_at,
             :payment_type, :fixed_daily_pay
  end
end
