# frozen_string_literal: true

require "rqrcode"

# Generates QR code PNG binary for use in emails and other contexts.
module QrCodeHelper
  # Generate a QR code PNG as binary string.
  # The QR encodes the ticket URL: {frontend_url}/{slug}/ticket/{code}
  def self.ticket_qr_png(appointment)
    frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:3000")
    slug = appointment.business.slug
    code = appointment.ticket_code
    url = "#{frontend_url}/#{slug}/ticket/#{code}"

    qr = RQRCode::QRCode.new(url, level: :m)
    qr.as_png(size: 280, border_modules: 2).to_s
  end
end
