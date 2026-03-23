# frozen_string_literal: true

ActiveAdmin.register DiscountCode do
  menu priority: 12, label: "Discount Codes"

  permit_params :business_id, :code, :name, :discount_type, :discount_value,
                :max_uses, :valid_from, :valid_until, :active, :source, :customer_id

  # -- Index --
  index do
    selectable_column
    id_column
    column :code
    column :name
    column(:business) { |dc| dc.business&.name }
    column :discount_type
    column :discount_value
    column :max_uses
    column :current_uses
    column(:active) { |dc| status_tag(dc.active? ? "Activo" : "Inactivo", class: dc.active? ? "ok" : "error") }
    column :source
    column :valid_from
    column :valid_until
    column :created_at
    actions
  end

  # -- Filters --
  filter :code
  filter :name
  filter :business
  filter :discount_type, as: :select, collection: %w[percentage fixed]
  filter :active
  filter :source, as: :select, collection: %w[manual birthday referral promo]
  filter :valid_from
  filter :valid_until
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row :code
      row :name
      row(:business) { |dc| link_to dc.business.name, admin_business_path(dc.business) }
      row(:customer) { |dc| dc.customer ? link_to(dc.customer.name, admin_customer_path(dc.customer)) : "General (todos)" }
      row :discount_type
      row :discount_value
      row :max_uses
      row :current_uses
      row(:active) { |dc| status_tag(dc.active? ? "Activo" : "Inactivo", class: dc.active? ? "ok" : "error") }
      row :source
      row :valid_from
      row :valid_until
      row :created_at
      row :updated_at
    end

    panel "Appointments using this code" do
      table_for resource.appointments.includes(:customer, :service).limit(20) do
        column(:id) { |a| link_to a.id, admin_appointment_path(a) }
        column(:customer) { |a| a.customer&.name }
        column(:service) { |a| a.service&.name }
        column :appointment_date
        column :discount_amount
        column :price
      end
    end
  end

  # -- Form --
  form do |f|
    f.inputs "Discount Code" do
      f.input :business, as: :select, collection: Business.active.pluck(:name, :id)
      f.input :code
      f.input :name
      f.input :discount_type, as: :select, collection: %w[percentage fixed]
      f.input :discount_value
      f.input :max_uses
      f.input :valid_from, as: :datepicker
      f.input :valid_until, as: :datepicker
      f.input :active
      f.input :source, as: :select, collection: %w[manual birthday referral promo], include_blank: true
      f.input :customer, as: :select, collection: Customer.all.pluck(:name, :id), include_blank: "General (todos)"
    end
    f.actions
  end
end
