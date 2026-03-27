# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["MAILER_FROM"] || "Agendity <#{SiteConfig.get('support_email') || 'contacto@agendity.co'}>" }
  layout "mailer"
end
