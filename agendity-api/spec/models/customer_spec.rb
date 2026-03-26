require "rails_helper"

RSpec.describe Customer, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:appointments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:reviews).dependent(:nullify) }
    it { is_expected.to have_many(:credit_accounts).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:customer, business: business) }

    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:business_id).allow_blank }
  end

  describe "scopes" do
    describe ".with_email" do
      let!(:with_email) { create(:customer, business: business, email: "test@example.com") }
      let!(:no_email)   { create(:customer, business: business, email: nil) }

      it "returns only customers with email" do
        expect(described_class.with_email).to include(with_email)
        expect(described_class.with_email).not_to include(no_email)
      end
    end

    describe ".with_birthday_on" do
      let!(:birthday_customer) { create(:customer, business: business, birth_date: Date.new(1990, 3, 24)) }
      let!(:other_customer)    { create(:customer, business: business, birth_date: Date.new(1990, 5, 15)) }

      it "returns customers with birthday on given month/day" do
        expect(described_class.with_birthday_on(3, 24)).to include(birthday_customer)
        expect(described_class.with_birthday_on(3, 24)).not_to include(other_customer)
      end
    end

    describe ".with_birthday_in_range" do
      let!(:birthday_customer) { create(:customer, business: business, birth_date: Date.new(1990, 3, 24)) }

      it "returns customers with birthday in range" do
        from = Date.new(2000, 3, 20)
        to = Date.new(2000, 3, 30)
        expect(described_class.with_birthday_in_range(from, to)).to include(birthday_customer)
      end
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to include("name", "email")
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to include("business", "appointments")
    end
  end
end
