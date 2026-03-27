# frozen_string_literal: true

# Register email observer to log all sent emails.
Rails.application.config.after_initialize do
  ActionMailer::Base.register_observer(EmailLogging)
end
