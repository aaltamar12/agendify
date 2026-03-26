require "rails_helper"

RSpec.describe Review, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:customer).optional }
    it { is_expected.to belong_to(:appointment).optional }
    it { is_expected.to belong_to(:employee).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:rating) }

    it "validates rating is between 1 and 5" do
      review = build(:review, business: business, rating: 0)
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to be_present

      review.rating = 6
      expect(review).not_to be_valid

      review.rating = 3
      expect(review).to be_valid
    end
  end

  describe "callbacks" do
    it "updates business rating_average after create" do
      customer = create(:customer, business: business)
      create(:review, business: business, customer: customer, rating: 4)
      create(:review, business: business, customer: customer, rating: 2)
      business.reload
      expect(business.rating_average).to eq(3.0)
      expect(business.total_reviews).to eq(2)
    end

    it "updates business rating_average after destroy" do
      customer = create(:customer, business: business)
      review = create(:review, business: business, customer: customer, rating: 5)
      create(:review, business: business, customer: customer, rating: 3)
      review.destroy
      business.reload
      expect(business.rating_average).to eq(3.0)
      expect(business.total_reviews).to eq(1)
    end

    context "employee rating" do
      let(:employee) { create(:employee, business: business) }
      let(:customer) { create(:customer, business: business) }

      it "updates employee rating_average and total_reviews after create" do
        create(:review, business: business, customer: customer, employee: employee, rating: 5)
        create(:review, business: business, customer: customer, employee: employee, rating: 3)
        employee.reload
        expect(employee.rating_average).to eq(4.0)
        expect(employee.total_reviews).to eq(2)
      end

      it "recalculates employee rating after destroy" do
        review = create(:review, business: business, customer: customer, employee: employee, rating: 5)
        create(:review, business: business, customer: customer, employee: employee, rating: 3)
        review.destroy
        employee.reload
        expect(employee.rating_average).to eq(3.0)
        expect(employee.total_reviews).to eq(1)
      end

      it "does not fail when review has no employee" do
        expect {
          create(:review, business: business, customer: customer, employee: nil, rating: 4)
        }.not_to raise_error
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
