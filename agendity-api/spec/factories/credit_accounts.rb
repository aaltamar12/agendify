FactoryBot.define do
  factory :credit_account do
    association :customer
    association :business
    balance { 0 }
  end
end
