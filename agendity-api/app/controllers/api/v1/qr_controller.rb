# frozen_string_literal: true

module Api
  module V1
    # Generates the public booking URL for the current business.
    # SRP: Only handles the QR URL generation concern.
    class QrController < BaseController
      # POST /api/v1/qr/generate
      def generate
        slug = current_business.slug
        base_url = Rails.application.config.x.frontend_url || ENV.fetch("FRONTEND_URL", "https://agendity.co")
        booking_url = "#{base_url}/#{slug}"

        render_success({ url: booking_url, slug: slug })
      end
    end
  end
end
