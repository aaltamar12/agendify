# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Agendify <no-reply@agendify.com>"
  layout "mailer"
end
