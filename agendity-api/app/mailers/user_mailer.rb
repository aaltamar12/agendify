# frozen_string_literal: true

# Sends transactional emails related to user account events.
class UserMailer < ApplicationMailer
  def reset_password(user, token)
    @user = user
    @reset_url = "#{frontend_url}/reset-password?token=#{token}"

    mail(
      to: @user.email,
      subject: "Restablecer tu contraseña — Agendity"
    )
  end

  private

  def frontend_url
    ENV.fetch("FRONTEND_URL", "http://localhost:3000")
  end
end
