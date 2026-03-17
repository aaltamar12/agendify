FactoryBot.define do
  factory :blocked_slot do
    association :business
    date { Date.tomorrow }
    start_time { "12:00" }
    end_time { "13:00" }
    reason { "Almuerzo" }
  end
end
