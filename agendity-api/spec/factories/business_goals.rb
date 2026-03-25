FactoryBot.define do
  factory :business_goal do
    association :business
    goal_type { "monthly_sales" }
    name { "Meta mensual" }
    target_value { 5_000_000 }
    active { true }
  end
end
