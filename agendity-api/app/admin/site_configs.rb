# frozen_string_literal: true

ActiveAdmin.register SiteConfig do
  menu parent: "Configuración", priority: 1, label: "Configuración General"
  permit_params :value

  actions :index, :show, :edit, :update

  # -- Index --
  index do
    column :key
    column :description
    column(:value) { |c| truncate(c.value, length: 80) }
    column :updated_at
    actions defaults: false do |config|
      item "Editar", edit_admin_site_config_path(config)
    end
  end

  # -- Filters --
  filter :key

  # -- Form (only value is editable) --
  form do |f|
    f.inputs "Configuracion" do
      f.input :key, input_html: { disabled: true }
      f.input :description, input_html: { disabled: true }
      f.input :value, as: :text, hint: "Modifica el valor de esta configuracion"
    end
    f.actions
  end

  # -- Show --
  show do
    attributes_table do
      row :key
      row :description
      row :value
      row :updated_at
    end
  end
end
