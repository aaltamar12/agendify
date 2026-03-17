FactoryBot.define do
  factory :appointment do
    association :business
    association :employee
    association :service
    association :customer
    appointment_date { Date.tomorrow }
    start_time { "10:00" }
    end_time { "10:30" }
    price { 25_000 }
    status { :pending_payment }
    ticket_code { SecureRandom.hex(6).upcase }

    trait :confirmed do
      status { :confirmed }
    end

    trait :completed do
      status { :completed }
    end
  end
end
