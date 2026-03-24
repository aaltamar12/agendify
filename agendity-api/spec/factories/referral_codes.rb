FactoryBot.define do
  factory :referral_code do
    sequence(:code) { |n| "REF#{n}CODE" }
    referrer_name { Faker::Name.name }
    referrer_email { Faker::Internet.email }
    commission_percentage { 10.0 }
    status { :active }
  end
end
