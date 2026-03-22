# frozen_string_literal: true

ActiveAdmin.register NotificationEventConfig do
  menu label: "Notification Events", parent: "Settings", priority: 1

  permit_params :event_key, :title, :body_template,
                :browser_notification, :sound_enabled, :in_app_notification, :active

  # -- Index --
  index do
    selectable_column
    id_column
    column :event_key
    column :title
    column :body_template
    bool_column :browser_notification
    bool_column :sound_enabled
    bool_column :in_app_notification
    bool_column :active
    column :updated_at
    actions
  end

  # -- Filters --
  filter :event_key
  filter :title
  filter :browser_notification
  filter :sound_enabled
  filter :in_app_notification
  filter :active

  # -- Show --
  show do
    attributes_table do
      row :id
      row :event_key
      row :title
      row :body_template
      row :browser_notification
      row :sound_enabled
      row :in_app_notification
      row :active
      row :created_at
      row :updated_at
    end
  end

  # -- Form --
  form do |f|
    f.inputs "Notification Event Config" do
      f.input :event_key
      f.input :title
      f.input :body_template, hint: "Variables: {{customer_name}}, {{service_name}}, etc."
      f.input :browser_notification
      f.input :sound_enabled
      f.input :in_app_notification
      f.input :active
    end
    f.actions
  end
end
