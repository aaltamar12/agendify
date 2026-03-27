# frozen_string_literal: true

ActiveAdmin.register EmailLog do
  menu parent: "Herramientas", priority: 3, label: "Emails Enviados"

  actions :index, :show

  filter :recipient
  filter :subject
  filter :mailer_class
  filter :status
  filter :created_at

  index do
    id_column
    column :recipient
    column :subject
    column :mailer_class
    column :status do |log|
      status_tag log.status, class: log.status == "sent" ? "ok" : "error"
    end
    column :sent_at
    actions
  end

  show do
    attributes_table do
      row :recipient
      row :subject
      row :mailer_class
      row :mailer_action
      row :status
      row :error_message
      row :sent_at
      row :created_at
    end

    panel "HTML del Email" do
      div style: "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 0; overflow: hidden;" do
        # Copy button
        div style: "padding: 12px; background: #f9fafb; border-bottom: 1px solid #ddd; text-align: right;" do
          a "Copiar HTML", href: "#", onclick: "navigator.clipboard.writeText(document.getElementById('email-html-source').textContent); this.textContent='Copiado!'; setTimeout(() => this.textContent='Copiar HTML', 2000); return false;", style: "background: #7c3aed; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: 600;"
        end
        # Rendered preview
        div style: "padding: 20px;" do
          div resource.body_html.html_safe if resource.body_html.present?
        end
        # Hidden source for copy
        pre id: "email-html-source", style: "display: none;" do
          text_node resource.body_html
        end
      end
    end if resource.body_html.present?
  end
end
