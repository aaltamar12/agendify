# frozen_string_literal: true

ActiveAdmin.register SiteConfig do
  menu priority: 13, label: "Site Configs"
  permit_params :key, :value, :description

  # -- Index --
  index do
    selectable_column
    id_column
    column :key
    column(:value) { |c| truncate(c.value, length: 80) }
    column :description
    column :updated_at
    actions
  end

  # -- Filters --
  filter :key
  filter :description

  # -- Form --
  form do |f|
    f.inputs "Configuration" do
      f.input :key
      f.input :value, as: :text
      f.input :description
    end
    f.actions
  end

  # -- Show --
  show do
    attributes_table do
      row :id
      row :key
      row :value
      row :description
      row :created_at
      row :updated_at
    end
  end
end
