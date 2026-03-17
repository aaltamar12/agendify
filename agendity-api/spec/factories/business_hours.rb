FactoryBot.define do
  factory :business_hour do
    association :business
    day_of_week { 1 }
    open_time { "08:00" }
    close_time { "18:00" }
    closed { false }
  end
end
