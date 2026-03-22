require "rails_helper"

RSpec.describe DynamicPricing, type: :model do
  describe "associations" do
    it { should belong_to(:business) }
    it { should belong_to(:service).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }

    it "requires end_date to be after start_date" do
      dp = build(:dynamic_pricing, start_date: Date.current, end_date: Date.current - 1.day)
      expect(dp).not_to be_valid
      expect(dp.errors[:end_date]).to be_present
    end

    it "requires adjustment_value for fixed_mode" do
      dp = build(:dynamic_pricing, adjustment_mode: :fixed_mode, adjustment_value: nil)
      expect(dp).not_to be_valid
      expect(dp.errors[:adjustment_value]).to be_present
    end

    it "requires adjustment_start_value and adjustment_end_value for progressive modes" do
      dp = build(:dynamic_pricing,
        adjustment_mode: :progressive_asc,
        adjustment_value: nil,
        adjustment_start_value: nil,
        adjustment_end_value: nil)
      expect(dp).not_to be_valid
      expect(dp.errors[:adjustment_start_value]).to be_present
      expect(dp.errors[:adjustment_end_value]).to be_present
    end
  end

  describe "no overlapping active pricings" do
    let(:business) { create(:business) }

    it "prevents overlapping active pricings for the same business" do
      create(:dynamic_pricing,
        business: business,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        status: :active)

      overlapping = build(:dynamic_pricing,
        business: business,
        start_date: Date.current + 10.days,
        end_date: Date.current + 40.days,
        status: :active)

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include("Ya existe una tarifa activa para este periodo")
    end

    it "allows overlapping suggested pricings" do
      create(:dynamic_pricing,
        business: business,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        status: :suggested)

      overlapping = build(:dynamic_pricing,
        business: business,
        start_date: Date.current + 10.days,
        end_date: Date.current + 40.days,
        status: :active)

      expect(overlapping).to be_valid
    end

    it "allows service-specific pricing to overlap with general pricing" do
      create(:dynamic_pricing,
        business: business,
        service: nil,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        status: :active)

      service = create(:service, business: business)
      service_specific = build(:dynamic_pricing,
        business: business,
        service: service,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        status: :active)

      expect(service_specific).to be_valid
    end
  end

  describe "#apply_to_price" do
    let(:business) { create(:business) }
    let(:date) { Date.current + 5.days }

    context "with fixed_mode percentage" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          price_adjustment_type: :percentage,
          adjustment_mode: :fixed_mode,
          adjustment_value: 15,
          start_date: Date.current,
          end_date: Date.current + 30.days,
          days_of_week: [])
      end

      it "applies percentage increase" do
        result = pricing.apply_to_price(30_000, date)
        # 30,000 + (30,000 * 15 / 100) = 30,000 + 4,500 = 34,500
        expect(result).to eq(34_500)
      end
    end

    context "with fixed_mode fixed amount" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          price_adjustment_type: :fixed,
          adjustment_mode: :fixed_mode,
          adjustment_value: 5_000,
          start_date: Date.current,
          end_date: Date.current + 30.days,
          days_of_week: [])
      end

      it "adds the fixed amount" do
        result = pricing.apply_to_price(30_000, date)
        expect(result).to eq(35_000)
      end
    end

    context "with negative values (discounts)" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          price_adjustment_type: :percentage,
          adjustment_mode: :fixed_mode,
          adjustment_value: -10,
          start_date: Date.current,
          end_date: Date.current + 30.days,
          days_of_week: [])
      end

      it "applies discount" do
        result = pricing.apply_to_price(30_000, date)
        # 30,000 + (30,000 * -10 / 100) = 30,000 - 3,000 = 27,000
        expect(result).to eq(27_000)
      end
    end

    context "with progressive_asc interpolation" do
      let(:pricing) do
        create(:dynamic_pricing, :progressive_asc,
          business: business,
          start_date: Date.current,
          end_date: Date.current + 10.days,
          adjustment_start_value: 0,
          adjustment_end_value: 20)
      end

      it "interpolates the adjustment at midpoint" do
        mid_date = Date.current + 5.days
        result = pricing.apply_to_price(30_000, mid_date)
        # At midpoint (5/10 = 50%): adjustment = 0 + (20 - 0) * 0.5 = 10%
        # 30,000 + (30,000 * 10 / 100) = 33,000
        expect(result).to eq(33_000)
      end

      it "returns base price at start" do
        result = pricing.apply_to_price(30_000, Date.current)
        # At start (0/10 = 0%): adjustment = 0%
        expect(result).to eq(30_000)
      end

      it "applies full adjustment at end" do
        result = pricing.apply_to_price(30_000, Date.current + 10.days)
        # At end (10/10 = 100%): adjustment = 20%
        # 30,000 + (30,000 * 20 / 100) = 36,000
        expect(result).to eq(36_000)
      end
    end

    context "with progressive_desc interpolation" do
      let(:pricing) do
        create(:dynamic_pricing, :progressive_desc,
          business: business,
          start_date: Date.current,
          end_date: Date.current + 10.days,
          adjustment_start_value: 20,
          adjustment_end_value: 0)
      end

      it "starts high and decreases" do
        result = pricing.apply_to_price(30_000, Date.current)
        # At start: adjustment = 20%
        expect(result).to eq(36_000)
      end

      it "decreases to zero at the end" do
        result = pricing.apply_to_price(30_000, Date.current + 10.days)
        # At end: adjustment = 0%
        expect(result).to eq(30_000)
      end
    end
  end

  describe "#applies_on_day?" do
    let(:business) { create(:business) }

    context "with specific days_of_week" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          days_of_week: [0, 6], # Sunday and Saturday
          start_date: Date.current,
          end_date: Date.current + 30.days)
      end

      it "returns true for matching days" do
        sunday = Date.current.beginning_of_week(:sunday)
        expect(pricing.applies_on_day?(sunday)).to be true
      end

      it "returns false for non-matching days" do
        monday = Date.current.beginning_of_week(:monday)
        expect(pricing.applies_on_day?(monday)).to be false
      end
    end

    context "with empty days_of_week (all days)" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          days_of_week: [],
          start_date: Date.current,
          end_date: Date.current + 30.days)
      end

      it "returns true for any day" do
        (0..6).each do |wday|
          date = Date.current + wday.days
          expect(pricing.applies_on_day?(date)).to be true
        end
      end
    end

    context "when date doesn't match days" do
      let(:pricing) do
        create(:dynamic_pricing,
          business: business,
          days_of_week: [0, 6],
          start_date: Date.current,
          end_date: Date.current + 30.days)
      end

      it "apply_to_price returns base price unchanged" do
        # Find a Tuesday (wday = 2)
        tuesday = Date.current
        tuesday += 1.day until tuesday.wday == 2

        result = pricing.apply_to_price(30_000, tuesday)
        expect(result).to eq(30_000)
      end
    end
  end

  describe "enums" do
    it { should define_enum_for(:price_adjustment_type).with_values(percentage: 0, fixed: 1) }
    it { should define_enum_for(:adjustment_mode).with_values(fixed_mode: 0, progressive_asc: 1, progressive_desc: 2) }
    it { should define_enum_for(:status).with_values(suggested: 0, active: 1, rejected: 2, expired: 3) }
  end
end
