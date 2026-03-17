FactoryBot.define do
  factory :service do
    association :business
    name { Faker::Commerce.product_name }
    price { Faker::Commerce.price(range: 15_000..80_000) }
    duration_minutes { 30 }
    active { true }
  end
end
