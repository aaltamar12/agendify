FactoryBot.define do
  factory :business do
    association :owner, factory: :user
    name { Faker::Company.name }
    slug { name.parameterize }
    business_type { :barbershop }
    phone { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    city { "Barranquilla" }
    country { "CO" }
    timezone { "America/Bogota" }
    currency { "COP" }
    status { :active }
    onboarding_completed { true }
    cancellation_policy_pct { 0 }
    cancellation_deadline_hours { 0 }
    rating_average { 0 }
    total_reviews { 0 }

    trait :with_hours do
      after(:create) do |business|
        (0..6).each do |day|
          create(:business_hour,
            business: business,
            day_of_week: day,
            open_time: "08:00",
            close_time: "18:00",
            closed: day == 0) # Sunday closed
        end
      end
    end
  end
end
