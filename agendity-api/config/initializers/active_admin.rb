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
end
