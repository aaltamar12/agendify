# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "Agendity <contacto@agendity.co>") }
  layout "mailer"
end
