# frozen_string_literal: true

ActiveAdmin.register Appointment do
  menu parent: "Citas", priority: 1, label: "Citas"

  actions :index, :show

  # -- Eager loading --
  includes :business, :customer, :service, :employee

  # -- Index --
  index do
    id_column
    column(:business) { |a| link_to a.business.name, admin_business_path(a.business) }
    column(:customer) { |a| a.customer&.name || "N/A" }
    column(:service) { |a| a.service.name }
    column(:employee) { |a| a.employee.name }
    column :appointment_date
    column :start_time
    column :status
    column(:price) { |a| "$#{a.price.to_f.round(0)} COP" }
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: -> { Appointment.statuses.keys }
  filter :business
  filter :appointment_date
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |a| link_to a.business.name, admin_business_path(a.business) }
      row(:customer) { |a| a.customer&.name || "N/A" }
      row(:service) { |a| a.service.name }
      row(:employee) { |a| a.employee.name }
      row :appointment_date
      row :start_time
      row :end_time
      row :status
      row(:price) { |a| "$#{a.price.to_f.round(0)} COP" }
      row :ticket_code
      row :notes
      row :cancellation_reason
      row :cancelled_by
      row :checked_in_at
      row :created_at
      row :updated_at
    end
  end
end
