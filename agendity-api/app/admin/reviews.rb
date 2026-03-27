# frozen_string_literal: true

ActiveAdmin.register Review do
  menu parent: "Configuración", priority: 5, label: "Reseñas"

  actions :index, :show

  # -- Eager loading --
  includes :business, :customer

  # -- Index --
  index do
    id_column
    column(:business) { |r| link_to r.business.name, admin_business_path(r.business) }
    column :customer_name
    column :rating
    column(:comment) { |r| truncate(r.comment.to_s, length: 80) }
    column :created_at
    actions
  end

  # -- Filters --
  filter :business
  filter :rating
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |r| link_to r.business.name, admin_business_path(r.business) }
      row :customer_name
      row(:customer) { |r| r.customer ? link_to(r.customer.name, admin_customer_path(r.customer)) : "N/A" }
      row :rating
      row :comment
      row :created_at
    end
  end
end
