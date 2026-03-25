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
  end
end
