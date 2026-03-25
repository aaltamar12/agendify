require "rails_helper"

RSpec.describe DiscountCode, type: :model do
  let(:business) { create(:business) }

  describe "validations" do
    subject { build(:discount_code, business: business) }

    # Note: validate_presence_of(:code) cannot be tested with shoulda-matchers
    # because the before_validation :generate_code callback auto-generates a code
    # when blank, so the model is always valid even with an empty code.
    it "auto-generates a code when blank" do
      code = build(:discount_code, business: business, code: "")
      code.valid?
      expect(code.code).to be_present
    end
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:business_id).case_insensitive }
    it { is_expected.to validate_numericality_of(:discount_value).is_greater_than(0) }

    context "when discount_type is percentage" do
      subject { build(:discount_code, business: business, discount_type: "percentage") }

      it { is_expected.to validate_numericality_of(:discount_value).is_less_than_or_equal_to(100) }
    end

    it "validates discount_type inclusion" do
      code = build(:discount_code, business: business, discount_type: "bogus")
      expect(code).not_to be_valid
      expect(code.errors[:discount_type]).to be_present
    end

    it "is valid with valid attributes" do
      code = build(:discount_code, business: business, discount_type: "percentage", discount_value: 15)
      expect(code).to be_valid
    end

    it "is valid with fixed discount_type" do
      code = build(:discount_code, business: business, discount_type: "fixed", discount_value: 5_000)
      expect(code).to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_code)   { create(:discount_code, business: business, active: true) }
      let!(:inactive_code) { create(:discount_code, business: business, active: false) }

      it "returns only active codes" do
        expect(described_class.active).to include(active_code)
        expect(described_class.active).not_to include(inactive_code)
      end
    end

    describe ".valid_now" do
      let!(:valid_code) do
        create(:discount_code,
          business: business,
          active: true,
          valid_from: 1.day.ago,
          valid_until: 1.day.from_now)
      end

      let!(:expired_code) do
        create(:discount_code,
          business: business,
          active: true,
          valid_from: 10.days.ago,
          valid_until: 1.day.ago)
      end

      let!(:future_code) do
        create(:discount_code,
          business: business,
          active: true,
          valid_from: 1.day.from_now,
          valid_until: 10.days.from_now)
      end

      let!(:no_dates_code) do
        create(:discount_code,
          business: business,
          active: true,
          valid_from: nil,
          valid_until: nil)
      end

      it "includes codes within valid date range" do
        expect(described_class.valid_now).to include(valid_code)
      end

      it "excludes expired codes" do
        expect(described_class.valid_now).not_to include(expired_code)
      end

      it "excludes future codes" do
        expect(described_class.valid_now).not_to include(future_code)
      end

      it "includes codes with no date restrictions" do
        expect(described_class.valid_now).to include(no_dates_code)
      end
    end

    describe ".available" do
      let!(:available_code) do
        create(:discount_code,
          business: business,
          active: true,
          max_uses: 10,
          current_uses: 5)
      end

      let!(:exhausted_code) do
        create(:discount_code,
          business: business,
          active: true,
          max_uses: 5,
          current_uses: 5)
      end

      let!(:unlimited_code) do
        create(:discount_code,
          business: business,
          active: true,
          max_uses: nil,
          current_uses: 100)
      end

      it "includes codes under max_uses limit" do
        expect(described_class.available).to include(available_code)
      end

      it "excludes exhausted codes" do
        expect(described_class.available).not_to include(exhausted_code)
      end

      it "includes codes with no max_uses limit" do
        expect(described_class.available).to include(unlimited_code)
      end
    end
  end

  describe "#apply_to" do
    context "percentage discount" do
      let(:code) { build(:discount_code, discount_type: "percentage", discount_value: 20, business: business) }

      it "calculates percentage of the price" do
        expect(code.apply_to(100_000)).to eq(20_000)
      end

      it "rounds to the nearest integer" do
        expect(code.apply_to(33_333)).to eq(6_667)
      end
    end

    context "fixed discount" do
      let(:code) { build(:discount_code, discount_type: "fixed", discount_value: 10_000, business: business) }

      it "returns the fixed discount amount" do
        expect(code.apply_to(50_000)).to eq(10_000)
      end

      it "caps at the price (cannot discount more than the price)" do
        expect(code.apply_to(5_000)).to eq(5_000)
      end
    end
  end

  describe "#record_use!" do
    let(:code) { create(:discount_code, business: business, current_uses: 3) }

    it "increments current_uses by 1" do
      expect { code.record_use! }.to change { code.reload.current_uses }.from(3).to(4)
    end
  end

  describe "#usable?" do
    context "when active, not expired, not exhausted" do
      let(:code) do
        build(:discount_code,
          business: business,
          active: true,
          valid_until: 1.day.from_now,
          max_uses: 10,
          current_uses: 5)
      end

      it "returns true" do
        expect(code.usable?).to be true
      end
    end

    context "when inactive" do
      let(:code) { build(:discount_code, business: business, active: false) }

      it "returns false" do
        expect(code.usable?).to be false
      end
    end

    context "when expired" do
      let(:code) { build(:discount_code, business: business, active: true, valid_until: 1.day.ago) }

      it "returns false" do
        expect(code.usable?).to be false
      end
    end

    context "when exhausted" do
      let(:code) { build(:discount_code, business: business, active: true, max_uses: 5, current_uses: 5) }

      it "returns false" do
        expect(code.usable?).to be false
      end
    end

    context "when no valid_until (never expires)" do
      let(:code) { build(:discount_code, business: business, active: true, valid_until: nil) }

      it "returns true" do
        expect(code.usable?).to be true
      end
    end

    context "when no max_uses (unlimited)" do
      let(:code) { build(:discount_code, business: business, active: true, max_uses: nil, current_uses: 999) }

      it "returns true" do
        expect(code.usable?).to be true
      end
    end
  end

  describe "auto-generate code" do
    it "generates a code when code is blank on create" do
      code = create(:discount_code, business: business, code: nil)

      expect(code.code).to be_present
      expect(code.code.length).to eq(8)
    end

    it "does not overwrite an existing code" do
      code = create(:discount_code, business: business, code: "MYCODE")

      expect(code.code).to eq("MYCODE")
    end
  end

  describe "upcase_code callback" do
    it "upcases the code before validation" do
      code = create(:discount_code, business: business, code: "lowercase")

      expect(code.code).to eq("LOWERCASE")
    end
  end
end
