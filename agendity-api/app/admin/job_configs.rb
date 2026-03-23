# frozen_string_literal: true

ActiveAdmin.register JobConfig do
  menu priority: 14, label: "Jobs"

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
