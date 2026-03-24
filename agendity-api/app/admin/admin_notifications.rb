# frozen_string_literal: true

ActiveAdmin.register AdminNotification do
  menu priority: 2, label: -> { "Notificaciones (#{AdminNotification.unread.count})" }

  actions :index, :show

  filter :title
  filter :notification_type
  filter :read
  filter :created_at

  scope :all, default: true
  scope("No leidas") { |scope| scope.unread }

  index do
    selectable_column
    id_column
    column :icon
    column :title do |n|
      span n.title, style: n.read? ? "" : "font-weight: bold;"
    end
    column :notification_type
    column(:read) { |n| status_tag(n.read? ? "Leida" : "No leida", class: n.read? ? "ok" : "error") }
    column :created_at
    actions defaults: false do |n|
      links = []
      links << link_to("Ver", admin_admin_notification_path(n))
      links << link_to("Marcar leida", mark_read_admin_admin_notification_path(n), method: :put) unless n.read?
      links << link_to("Ir al recurso", n.link) if n.link.present?
      safe_join(links, " | ")
    end
  end

  show do
    attributes_table do
      row :id
      row :icon
      row :title
      row :body
      row :notification_type
      row(:link) { |n| n.link.present? ? link_to(n.link, n.link) : "-" }
      row(:read) { |n| status_tag(n.read? ? "Leida" : "No leida", class: n.read? ? "ok" : "error") }
      row :created_at
      row :updated_at
    end

    panel "Acciones" do
      unless resource.read?
        para link_to("Marcar como leida", mark_read_admin_admin_notification_path(resource), method: :put, class: "button")
      end
      if resource.link.present?
        para link_to("Ir al recurso", resource.link, class: "button")
      end
    end
  end

  member_action :mark_read, method: :put do
    resource.mark_read!
    redirect_to admin_admin_notifications_path, notice: "Notificacion marcada como leida"
  end

  collection_action :mark_all_read, method: :put do
    AdminNotification.mark_all_read!
    redirect_to admin_admin_notifications_path, notice: "Todas las notificaciones marcadas como leidas"
  end

  action_item :mark_all_read, only: :index do
    link_to "Marcar todas como leidas", mark_all_read_admin_admin_notifications_path, method: :put
  end

  batch_action :mark_read do |ids|
    batch_action_collection.find(ids).each(&:mark_read!)
    redirect_to collection_path, notice: "Notificaciones marcadas como leidas"
  end
end
