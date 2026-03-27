# frozen_string_literal: true

ActiveAdmin.register JobConfig do
  menu parent: "Configuración", priority: 4, label: "Jobs"

  permit_params :enabled

  actions :index, :show, :edit, :update

  filter :name
  filter :enabled
  filter :last_run_status

  index do
    column :name
    column :job_class
    column :schedule
    column(:enabled) { |j| status_tag(j.enabled? ? "Activo" : "Desactivado", class: j.enabled? ? "ok" : "error") }
    column(:last_run_at) { |j| j.last_run_at ? time_ago_in_words(j.last_run_at) + " ago" : "Nunca" }
    column(:last_run_status) { |j|
      if j.last_run_status == "success"
        status_tag("OK", class: "ok")
      elsif j.last_run_status == "error"
        status_tag("Error", class: "error")
      else
        "—"
      end
    }
    actions defaults: true do |job|
      item "Run now", run_admin_job_config_path(job), method: :post, class: "button small"
    end
  end

  show do
    attributes_table do
      row :name
      row :job_class
      row :description
      row :schedule
      row(:enabled) { |j| status_tag(j.enabled? ? "Activo" : "Desactivado", class: j.enabled? ? "ok" : "error") }
      row :last_run_at
      row(:last_run_status) { |j|
        if j.last_run_status == "success"
          status_tag("OK", class: "ok")
        elsif j.last_run_status == "error"
          status_tag("Error", class: "error")
        else
          "—"
        end
      }
      row :last_run_message
      row :updated_at
    end

    div class: "action_items" do
      span class: "action_item" do
        link_to "Run now", run_admin_job_config_path(resource), method: :post, class: "button"
      end
    end

    # Map job classes to keywords for searching ActivityLog
    job_keywords = {
      "CompleteAppointmentsJob" => %w[appointment_completed complete_appointment],
      "AppointmentReminderSchedulerJob" => %w[reminder_sent reminder_scheduled reminder],
      "Intelligence::PricingSuggestionJob" => %w[ai_suggestion pricing_suggestion],
    }

    job_class_name = resource.job_class.to_s
    # Use mapped keywords or derive from job class name
    keywords = job_keywords[job_class_name] || [job_class_name.demodulize.underscore.sub(/_job$/, "")]

    # Build query: match action or description against any keyword
    conditions = keywords.flat_map { |kw|
      ["action ILIKE ?", "description ILIKE ?"]
    }
    values = keywords.flat_map { |kw|
      ["%#{kw}%", "%#{kw}%"]
    }
    where_clause = conditions.join(" OR ")

    logs = ActivityLog
      .where("created_at >= ?", 24.hours.ago)
      .where(where_clause, *values)
      .order(created_at: :desc)
      .limit(100)

    panel "Historial de ejecuciones (últimas 24h)" do
      if logs.any?
        table_for logs do
          column("Hora") { |log| l(log.created_at, format: :short) }
          column("Acción") { |log| status_tag(log.action) }
          column("Descripción") { |log| truncate(log.description, length: 120) }
          column("Negocio") { |log| log.business&.name || "—" }
          column("Metadata") { |log|
            if log.metadata.present?
              truncate(log.metadata.to_json, length: 80)
            else
              "—"
            end
          }
        end
      else
        div class: "blank_slate_container" do
          span class: "blank_slate" do
            span "No hay ejecuciones registradas en las últimas 24h"
          end
        end
      end
    end
  end

  form do |f|
    f.inputs "Configuracion" do
      f.input :enabled, label: "Habilitado"
    end
    f.actions
  end

  # POST action to run a job manually
  member_action :run, method: :post do
    job_config = JobConfig.find(params[:id])
    begin
      job_class = job_config.job_class.constantize
      job_class.perform_later
      redirect_to admin_job_config_path(job_config), notice: "Job '#{job_config.name}' ejecutado. Revisa el estado en unos segundos."
    rescue StandardError => e
      redirect_to admin_job_config_path(job_config), alert: "Error al ejecutar: #{e.message}"
    end
  end
end
