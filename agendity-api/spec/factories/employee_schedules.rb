FactoryBot.define do
  factory :employee_schedule do
    association :employee
    day_of_week { 1 }
    start_time { "08:00" }
    end_time { "18:00" }
  end
end
