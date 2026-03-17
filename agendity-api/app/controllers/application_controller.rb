# frozen_string_literal: true

# Base controller for the entire application.
# Inherits from ActionController::Base so that ActiveAdmin (which depends on
# InheritedResources::Base < ::ApplicationController) gets sessions, cookies,
# flash, helpers, and CSRF protection.
#
# API controllers inherit from ApiController (ActionController::API) instead.
class ApplicationController < ActionController::Base
  private

  # Called by ActiveAdmin via config.authentication_method
  def authenticate_admin!
    unless current_admin_user&.admin?
      redirect_to admin_login_path, alert: "You must sign in as admin."
    end
  end

  # Called by ActiveAdmin via config.current_user_method
  def current_admin_user
    return @current_admin_user if defined?(@current_admin_user)

    user_id = session[:admin_user_id]
    @current_admin_user = user_id ? User.find_by(id: user_id, role: :admin) : nil
  end
  helper_method :current_admin_user
end
