require "rails_helper"

RSpec.describe BusinessSerializer do
  let(:business) { create(:business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(business)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "slug", "phone", "city", "status", "logo_url", "cover_url")
  end

  it "handles business without subscriptions" do
    expect(result["current_subscription"]).to be_nil
    expect(result["featured"]).to eq(false)
  end

  it "returns dynamic_pricing_coverage of 0.0 when no active pricings" do
    expect(result["dynamic_pricing_coverage"]).to eq(0.0)
  end

  context "with active subscription" do
    let(:plan) { create(:plan, featured_listing: true, ai_features: true) }

    before do
      create(:subscription, business: business, plan: plan, status: :active,
             start_date: Date.current, end_date: 30.days.from_now)
    end

    it "returns featured as true" do
      expect(result["featured"]).to eq(true)
    end

    it "includes current_subscription" do
      expect(result["current_subscription"]).not_to be_nil
    end
  end

  context "with logo attached" do
    before do
      business.logo.attach(io: StringIO.new("fake"), filename: "logo.png", content_type: "image/png")
    end

    it "returns ActiveStorage URL for logo_url" do
      expect(result["logo_url"]).to include("logo.png")
    end
  end

  context "without logo attached" do
    it "falls back to legacy logo_url column" do
      business.update_column(:logo_url, "https://example.com/logo.png")
      parsed = JSON.parse(described_class.render(business.reload))
      expect(parsed["logo_url"]).to eq("https://example.com/logo.png")
    end
  end

  context "with cover_image attached" do
    before do
      business.cover_image.attach(io: StringIO.new("fake"), filename: "cover.jpg", content_type: "image/jpeg")
    end

    it "returns ActiveStorage URL for cover_url" do
      expect(result["cover_url"]).to include("cover.jpg")
    end
  end

  context "without cover_image attached" do
    it "falls back to legacy cover_image_url" do
      business.update_column(:cover_image_url, "https://example.com/cover.jpg")
      parsed = JSON.parse(described_class.render(business.reload))
      expect(parsed["cover_url"]).to eq("https://example.com/cover.jpg")
    end
  end

  context "with dynamic pricing coverage" do
    let!(:service1) { create(:service, business: business, active: true) }
    let!(:service2) { create(:service, business: business, active: true) }

    it "returns 1.0 when a global pricing (nil service_id) is active" do
      create(:dynamic_pricing, business: business, service: nil, status: :active)
      parsed = JSON.parse(described_class.render(business.reload))
      expect(parsed["dynamic_pricing_coverage"]).to eq(1.0)
    end

    it "returns fractional coverage for service-specific pricings" do
      create(:dynamic_pricing, business: business, service: service1, status: :active)
      parsed = JSON.parse(described_class.render(business.reload))
      expect(parsed["dynamic_pricing_coverage"]).to eq(0.5)
    end
  end

  describe "explore view" do
    subject(:explore_result) { JSON.parse(described_class.render(business, view: :explore)) }

    it "excludes sensitive fields" do
      expect(explore_result).not_to have_key("owner_id")
      expect(explore_result).not_to have_key("nequi_phone")
    end

    it "includes verified field" do
      expect(explore_result).to have_key("verified")
      expect(explore_result["verified"]).to eq(false)
    end
  end
end
