# frozen_string_literal: true

# Logs every email sent by the application to the email_logs table.
# Captures recipient, subject, HTML body, and delivery status.
class EmailLogging
  def self.delivering_email(message)
    EmailLog.create!(
      recipient: Array(message.to).join(", "),
      subject: message.subject,
      mailer_class: message.delivery_handler&.name || "Unknown",
      mailer_action: message.instance_variable_get(:@_message_action) || "unknown",
      body_html: message.html_part&.body&.decoded || message.body&.decoded || "",
      status: "sent",
      sent_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.warn("[EmailLogging] Failed to log email: #{e.message}")
  end

  def self.delivered_email(message)
    # Already logged in delivering_email
  end
end
