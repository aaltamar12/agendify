FactoryBot.define do
  factory :review do
    association :business
    association :customer
    customer_name { customer.name }
    rating { rand(3..5) }
    comment { Faker::Lorem.sentence }
  end
end
