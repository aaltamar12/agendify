# frozen_string_literal: true

module Api
  module V1
    # Handles password reset flow: request reset email and reset password with token.
    class PasswordsController < BaseController
      skip_before_action :authenticate_user!
      skip_before_action :require_business!
      skip_before_action :render_empty_for_admin_without_business!

      # POST /api/v1/auth/forgot_password
      def forgot_password
        user = User.find_by(email: params[:email]&.downcase&.strip)

        if user
          raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
          user.update_columns(reset_password_token: hashed_token, reset_password_sent_at: Time.current)
          UserMailer.reset_password(user, raw_token).deliver_later
        end

        # Always return success to prevent email enumeration
        render_success({ message: "Si el correo existe, recibirás instrucciones para restablecer tu contraseña." })
      end

      # POST /api/v1/auth/reset_password
      def reset_password
        user = User.reset_password_by_token(
          reset_password_token: params[:token],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )

        if user.errors.empty?
          render_success({ message: "Contraseña actualizada exitosamente." })
        else
          render_error(
            user.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: user.errors.messages
          )
        end
      end
    end
  end
end
