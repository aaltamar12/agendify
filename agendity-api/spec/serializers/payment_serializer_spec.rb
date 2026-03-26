require "rails_helper"

RSpec.describe PaymentSerializer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let(:appointment) do
    create(:appointment, business: business, employee: employee, customer: customer, service: service)
  end
  let(:payment) { create(:payment, appointment: appointment) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(payment)) }

  it "renders expected keys" do
    expect(result).to include("id", "appointment_id", "payment_method", "amount", "status", "proof_url")
  end

  it "returns nil proof_url when no proof attached and no URL stored" do
    expect(result["proof_url"]).to be_nil
  end

  it "returns stored proof_image_url when present" do
    payment.update!(proof_image_url: "https://example.com/proof.jpg")
    result = JSON.parse(described_class.render(payment))
    expect(result["proof_url"]).to eq("https://example.com/proof.jpg")
  end

  it "prepends API_HOST for relative proof_image_url" do
    payment.update!(proof_image_url: "/uploads/proof.jpg")
    result = JSON.parse(described_class.render(payment))
    expect(result["proof_url"]).to include("/uploads/proof.jpg")
  end

  it "returns ActiveStorage URL when proof_image is attached" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/proof.png"), "image/png")
    appointment.proof_image.attach(file)
    result = JSON.parse(described_class.render(payment))
    expect(result["proof_url"]).to include("rails/active_storage")
  end
end
