require "rails_helper"

RSpec.describe Service, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:duration_minutes) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:duration_minutes).is_greater_than(0) }
  end

  describe "associations" do
    it { should belong_to(:business) }
    it { should have_many(:employee_services).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_services) }
    it { should have_many(:appointments).dependent(:restrict_with_error) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active services" do
        business = create(:business)
        active_svc = create(:service, business: business, active: true)
        inactive_svc = create(:service, business: business, active: false)

        expect(described_class.active).to include(active_svc)
        expect(described_class.active).not_to include(inactive_svc)
      end
    end

    describe ".for_business" do
      it "returns services for the given business" do
        business = create(:business)
        svc = create(:service, business: business)
        other = create(:service) # different business

        expect(described_class.for_business(business.id)).to include(svc)
        expect(described_class.for_business(business.id)).not_to include(other)
      end
    end
  end

  describe "validations edge cases" do
    it "is invalid with negative price" do
      svc = build(:service, price: -1)
      expect(svc).not_to be_valid
      expect(svc.errors[:price]).to be_present
    end

    it "is valid with zero price" do
      svc = build(:service, price: 0)
      expect(svc).to be_valid
    end

    it "is invalid with zero duration_minutes" do
      svc = build(:service, duration_minutes: 0)
      expect(svc).not_to be_valid
      expect(svc.errors[:duration_minutes]).to be_present
    end

    it "is invalid with negative duration_minutes" do
      svc = build(:service, duration_minutes: -5)
      expect(svc).not_to be_valid
      expect(svc.errors[:duration_minutes]).to be_present
    end

    it "is invalid without a name" do
      svc = build(:service, name: nil)
      expect(svc).not_to be_valid
      expect(svc.errors[:name]).to be_present
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to include("name", "price", "active")
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to include("business", "employees")
    end
  end
end
