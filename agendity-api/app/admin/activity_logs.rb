# frozen_string_literal: true

ActiveAdmin.register ActivityLog do
  menu priority: 8, label: "Activity Log"
  actions :index, :show, :destroy

  # -- Eager loading --
  includes :business

  # Root actions = the entry point of each appointment lifecycle
  ROOT_ACTIONS = %w[booking_created].freeze

  # -- Scopes --
  scope "Reservas", :reservations, default: true do |logs|
    logs.where(action: ROOT_ACTIONS)
  end
  scope "Todos los eventos", :all_events do |logs|
    logs.all
  end

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |log| link_to log.business.name, admin_business_path(log.business) }
    column :action
    column :actor_type
    column :actor_name
    column :description
    column("Resource") { |log| "#{log.resource_type} ##{log.resource_id}" if log.resource_type }
    column("Events") do |log|
      if log.resource_type && log.resource_id
        count = ActivityLog.where(resource_type: log.resource_type, resource_id: log.resource_id).count
        status_tag "#{count} eventos", class: count > 1 ? "warning" : "ok"
      end
    end
    column :created_at
    actions
  end

  # -- Filters --
  filter :business
  filter :action
  filter :actor_type
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |log| link_to log.business.name, admin_business_path(log.business) }
      row :action
      row :actor_type
      row :actor_name
      row :description
      row :resource_type
      row :resource_id
      row :metadata do |log|
        pre JSON.pretty_generate(log.metadata) if log.metadata.present?
      end
      row :ip_address
      row :created_at
    end

    # Show full lifecycle of the related resource
    if resource.resource_type.present? && resource.resource_id.present?
      panel "Ciclo de vida completo — #{resource.resource_type} ##{resource.resource_id}" do
        related = ActivityLog.where(
          resource_type: resource.resource_type,
          resource_id: resource.resource_id
        ).order(created_at: :asc)

        table_for related do
          column :created_at do |log|
            l(log.created_at, format: :long)
          end
          column :action
          column :actor_type
          column :actor_name
          column :description
        end
      end

      # Also show related Request Logs
      if defined?(RequestLog)
        panel "Request Logs relacionados — #{resource.resource_type} ##{resource.resource_id}" do
          requests = RequestLog.where(
            resource_type: resource.resource_type,
            resource_id: resource.resource_id
          ).order(created_at: :asc)

          table_for requests do
            column :created_at
            column :method
            column :path do |log|
              truncate(log.path, length: 50)
            end
            column :status_code do |log|
              status_tag log.status_code.to_s,
                class: log.status_code.to_i >= 500 ? "error" : (log.status_code.to_i >= 400 ? "warning" : "ok")
            end
            column :duration_ms do |log|
              "#{log.duration_ms}ms"
            end
            column :error_message do |log|
              truncate(log.error_message.to_s, length: 60) if log.error_message
            end
          end
        end
      end
    end
  end
end
