FactoryBot.define do
  factory :discount_code do
    association :business
    sequence(:code) { |n| "DISC#{n}" }
    discount_type { "percentage" }
    discount_value { 10 }
    active { true }
    current_uses { 0 }
  end
end
