FactoryBot.define do
  factory :appointment do
    association :business
    association :employee
    association :service
    association :customer
    appointment_date { Date.tomorrow }
    sequence(:start_time) { |n| format("%02d:%02d", (8 + (n * 30) / 60) % 24, (n * 30) % 60) }
    end_time { start_time.present? ? (Time.parse(start_time) + 30.minutes).strftime("%H:%M") : "10:30" }
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
