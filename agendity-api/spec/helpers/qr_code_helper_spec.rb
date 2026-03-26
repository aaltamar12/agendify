# frozen_string_literal: true

require "rails_helper"

RSpec.describe QrCodeHelper do
  describe ".ticket_qr_png" do
    let(:business) { create(:business, slug: "barberia-test") }
    let(:appointment) { create(:appointment, business: business, ticket_code: "ABC123") }

    it "generates a PNG binary string" do
      png = described_class.ticket_qr_png(appointment)

      expect(png).to be_a(String)
      expect(png.encoding).to eq(Encoding::ASCII_8BIT)
      # PNG files start with the PNG signature
      expect(png[0..3]).to eq("\x89PNG".b)
    end

    it "encodes the correct URL" do
      allow(ENV).to receive(:fetch).with("FRONTEND_URL", "http://localhost:3000").and_return("https://agendity.com")

      qr_double = instance_double(RQRCode::QRCode)
      png_double = double("ChunkyPNG", to_s: "png-data")

      expect(RQRCode::QRCode).to receive(:new)
        .with("https://agendity.com/barberia-test/ticket/ABC123", level: :m)
        .and_return(qr_double)
      expect(qr_double).to receive(:as_png).with(size: 280, border_modules: 2).and_return(png_double)

      result = described_class.ticket_qr_png(appointment)
      expect(result).to eq("png-data")
    end
  end
end
