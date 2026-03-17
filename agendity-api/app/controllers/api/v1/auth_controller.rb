# frozen_string_literal: true

module Api
  module V1
    # Handles authentication: login, register, token refresh, and session info.
    # SRP: Only manages HTTP auth concerns; delegates logic to Auth services.
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[login register refresh]
      skip_before_action :require_business!, only: %i[login register refresh me logout]

      # POST /api/v1/auth/login
      def login
        result = Auth::LoginService.call(**login_params.to_h.symbolize_keys)

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unauthorized, details: result.details)
        end
      end

      # POST /api/v1/auth/register
      def register
        result = Auth::RegisterService.call(**register_params.to_h.symbolize_keys)

        if result.success?
          render_success(result.data, status: :created)
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        result = Auth::RefreshTokenService.call(**refresh_params.to_h.symbolize_keys)

        if result.success?
          render_success(result.data)
        else
          render_error(result.error, status: :unauthorized, details: result.details)
        end
      end

      # GET /api/v1/auth/me
      def me
        render_success(UserSerializer.render_as_hash(current_user))
      end

      # DELETE /api/v1/auth/logout
      def logout
        result = Auth::LogoutService.call(user: current_user, token: request.headers["Authorization"]&.split(" ")&.last)

        if result.success?
          render_success({ message: "Sesión cerrada exitosamente" })
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      private

      def login_params
        params.permit(:email, :password)
      end

      def register_params
        params.permit(:name, :email, :password, :password_confirmation, :phone, :business_name, :business_type)
      end

      def refresh_params
        params.permit(:refresh_token)
      end
    end
  end
end
