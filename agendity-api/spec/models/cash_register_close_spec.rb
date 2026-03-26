require "rails_helper"

RSpec.describe CashRegisterClose, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:closed_by_user).class_name("User") }
    it { is_expected.to have_many(:employee_payments).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:cash_register_close, business: business) }

    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_uniqueness_of(:date).scoped_to(:business_id).with_message("ya se cerró caja de este día") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, closed: 1) }
  end

  describe "scopes" do
    describe ".recent" do
      it "returns closes ordered by date descending" do
        old_close = create(:cash_register_close, business: business, date: 3.days.ago)
        new_close = create(:cash_register_close, business: business, date: Date.current)
        expect(described_class.recent.first).to eq(new_close)
      end
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to be_an(Array)
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to be_an(Array)
    end
  end

end
