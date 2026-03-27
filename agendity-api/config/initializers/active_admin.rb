# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.site_title = "Agendity Admin"
  config.authentication_method = :authenticate_admin!
  config.current_user_method = :current_admin_user
  config.logout_link_path = "/admin/logout"
  config.logout_link_method = :get
  config.batch_actions = true
  config.comments = false
  config.filter_attributes = [:encrypted_password, :password, :password_confirmation]
  config.localize_format = :long

  config.namespace :admin do |admin|
    admin.build_menu do |menu|
      menu.add label: "Negocios", priority: 4
      menu.add label: "Citas", priority: 5
      menu.add label: "Finanzas", priority: 6
      menu.add label: "Planes y Suscripciones", priority: 7
      menu.add label: "Referidos", priority: 8
      menu.add label: "Configuración", priority: 9
      menu.add label: "Herramientas", priority: 10
    end
  end
end
