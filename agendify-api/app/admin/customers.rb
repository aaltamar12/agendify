# frozen_string_literal: true

ActiveAdmin.register Customer do
  actions :index, :show

  # -- Eager loading --
  includes :business

  # -- Index --
  index do
    id_column
    column(:business) { |c| link_to c.business.name, admin_business_path(c.business) }
    column :name
    column :email
    column :phone
    column(:pending_penalty) { |c| "$#{c.pending_penalty.to_f.round(0)} COP" if c.pending_penalty.to_f > 0 }
    column :created_at
    actions
  end

  # -- Filters --
  filter :business
  filter :name
  filter :email
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |c| link_to c.business.name, admin_business_path(c.business) }
      row :name
      row :email
      row :phone
      row :notes
      row(:pending_penalty) { |c| "$#{c.pending_penalty.to_f.round(0)} COP" }
      row :created_at
      row :updated_at
    end

    panel "Appointments" do
      table_for customer.appointments.includes(:service).order(appointment_date: :desc).limit(20) do
        column :appointment_date
        column(:service) { |a| a.service.name }
        column :status
        column(:price) { |a| "$#{a.price.to_f.round(0)} COP" }
      end
    end
  end
end
