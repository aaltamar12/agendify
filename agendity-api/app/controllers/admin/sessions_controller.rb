# frozen_string_literal: true

module Admin
  # Handles admin login/logout via session-based auth (not JWT).
  # Completely separate from the API authentication flow.
  class SessionsController < ApplicationController
    layout false

    def new
      if session[:admin_user_id] && User.find_by(id: session[:admin_user_id])&.admin?
        redirect_to admin_root_path
      end
    end

    def create
      user = User.find_by(email: params[:email])

      if user&.valid_password?(params[:password]) && user.admin?
        session[:admin_user_id] = user.id
        redirect_to admin_root_path, notice: "Signed in successfully."
      else
        flash.now[:error] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_user_id)
      redirect_to admin_login_path, notice: "Signed out successfully."
    end
  end
end
