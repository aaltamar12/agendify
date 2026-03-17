FactoryBot.define do
  factory :employee do
    association :business
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.unique.email }
    active { true }
  end
end
