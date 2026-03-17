# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Agendity <no-reply@agendity.com>"
  layout "mailer"
end
