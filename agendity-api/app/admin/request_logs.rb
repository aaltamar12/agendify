# frozen_string_literal: true

ActiveAdmin.register RequestLog do
  menu parent: "Citas", priority: 3, label: "Request Logs"
  actions :index, :show, :destroy

  # -- Eager loading --
  includes :business

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |log| log.business ? link_to(log.business.name, admin_business_path(log.business)) : "N/A" }
    column :method
    column(:path) { |log| truncate(log.path, length: 50) }
    column(:status_code) do |log|
      status_tag log.status_code.to_s,
        class: log.server_error? ? "error" : (log.error? ? "warning" : "ok")
    end
    column(:duration_ms) { |log| "#{log.duration_ms}ms" }
    column(:error_message) { |log| truncate(log.error_message.to_s, length: 60) if log.error_message }
    column :resource_type
    column :resource_id
    column :created_at
    actions
  end

  # -- Filters --
  filter :business
  filter :method, as: :select, collection: %w[GET POST PUT PATCH DELETE]
  filter :status_code
  filter :path
  filter :controller_action
  filter :resource_type
  filter :created_at
  filter :error_message_cont, as: :string, label: "Error contains"

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |log| log.business ? link_to(log.business.name, admin_business_path(log.business)) : "N/A" }
      row :method
      row :path
      row :controller_action
      row(:status_code) do |log|
        status_tag log.status_code.to_s,
          class: log.server_error? ? "error" : (log.error? ? "warning" : "ok")
      end
      row :duration_ms
      row :ip_address
      row :user_agent
      row :request_id
      row :resource_type
      row :resource_id
      row(:request_params) { |log| pre(JSON.pretty_generate(log.request_params)) rescue pre(log.request_params.to_s) }
      row(:response_body) { |log| (pre(JSON.pretty_generate(log.response_body)) rescue pre(log.response_body.to_s)) if log.response_body.present? }
      row(:error_message) { |log| log.error_message }
      row(:error_backtrace) { |log| pre(log.error_backtrace.to_s) if log.error_backtrace.present? }
      row :created_at
    end

    # Show related activity logs via request_id
    panel "Related Activity Logs" do
      activity_logs = ActivityLog.where("metadata->>'request_id' = ?", resource.request_id)
      if activity_logs.any?
        table_for activity_logs do
          column(:id) { |al| link_to al.id, admin_activity_log_path(al) }
          column :action
          column :description
          column :created_at
        end
      else
        para "No related activity logs found."
      end
    end
  end
end
