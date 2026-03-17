# frozen_string_literal: true

class PaymentSerializer < Blueprinter::Base
  identifier :id

  fields :appointment_id, :payment_method, :amount,
         :status, :reference,
         :submitted_at, :approved_at, :rejected_at, :rejection_reason,
         :created_at, :updated_at

  # Serve proof image URL — prefer ActiveStorage attachment, fallback to stored string
  field :proof_url do |payment, _options|
    appointment = payment.appointment
    if appointment&.proof_image&.attached?
      Rails.application.routes.url_helpers.rails_blob_url(
        appointment.proof_image,
        host: ENV.fetch("API_HOST", "http://localhost:3001")
      )
    elsif payment.proof_image_url.present?
      # If it's a relative path, prepend the API host
      url = payment.proof_image_url
      url.start_with?("http") ? url : "#{ENV.fetch('API_HOST', 'http://localhost:3001')}#{url}"
    end
  end
end
