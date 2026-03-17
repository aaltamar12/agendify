FactoryBot.define do
  factory :customer do
    association :business
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.unique.email }
  end
end
