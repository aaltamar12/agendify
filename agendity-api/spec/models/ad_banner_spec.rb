require "rails_helper"

RSpec.describe AdBanner, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:placement) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_banner)   { create(:ad_banner, active: true) }
      let!(:inactive_banner) { create(:ad_banner, active: false) }

      it "returns only active banners" do
        expect(described_class.active).to include(active_banner)
        expect(described_class.active).not_to include(inactive_banner)
      end
    end

    describe ".for_placement" do
      let!(:top_banner)  { create(:ad_banner, placement: "dashboard_top") }
      let!(:side_banner) { create(:ad_banner, placement: "sidebar") }

      it "returns banners for the given placement" do
        expect(described_class.for_placement("dashboard_top")).to include(top_banner)
        expect(described_class.for_placement("dashboard_top")).not_to include(side_banner)
      end
    end

    describe ".current" do
      let!(:current_banner) { create(:ad_banner, start_date: 1.day.ago, end_date: 1.day.from_now) }
      let!(:expired_banner) { create(:ad_banner, start_date: 10.days.ago, end_date: 1.day.ago) }
      let!(:no_dates_banner) { create(:ad_banner, start_date: nil, end_date: nil) }

      it "includes current and no-date banners, excludes expired" do
        expect(described_class.current).to include(current_banner, no_dates_banner)
        expect(described_class.current).not_to include(expired_banner)
      end
    end
  end

  describe "#ctr" do
    it "calculates click-through rate" do
      banner = build(:ad_banner, impressions_count: 1000, clicks_count: 50)
      expect(banner.ctr).to eq(5.0)
    end

    it "returns 0 when no impressions" do
      banner = build(:ad_banner, impressions_count: 0, clicks_count: 0)
      expect(banner.ctr).to eq(0.0)
    end
  end

  describe "#display_image_url" do
    it "falls back to image_url field when no attachment" do
      banner = build(:ad_banner, image_url: "https://example.com/img.jpg")
      expect(banner.display_image_url).to eq("https://example.com/img.jpg")
    end

    it "returns ActiveStorage URL when image is attached" do
      banner = create(:ad_banner)
      banner.image.attach(io: StringIO.new("fake-image"), filename: "test.png", content_type: "image/png")

      url = banner.display_image_url
      expect(url).to include("test.png")
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(AdBanner.ransackable_attributes).to include("name", "placement", "active")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(AdBanner.ransackable_associations).to include("image_attachment")
    end
  end
end
