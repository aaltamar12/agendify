FactoryBot.define do
  factory :referral do
    association :referral_code
    association :business
    status { :pending }
  end
end
