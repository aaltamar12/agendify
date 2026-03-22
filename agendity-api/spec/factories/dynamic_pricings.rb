FactoryBot.define do
  factory :dynamic_pricing do
    association :business
    name { "Tarifa de prueba" }
    start_date { Date.current }
    end_date { Date.current + 30.days }
    price_adjustment_type { :percentage }
    adjustment_mode { :fixed_mode }
    adjustment_value { 10 }
    days_of_week { [] }
    status { :active }
    suggested_by { "manual" }

    trait :suggested do
      status { :suggested }
      suggested_by { "system" }
    end

    trait :progressive_asc do
      adjustment_mode { :progressive_asc }
      adjustment_value { nil }
      adjustment_start_value { 10 }
      adjustment_end_value { 25 }
    end

    trait :progressive_desc do
      adjustment_mode { :progressive_desc }
      adjustment_value { nil }
      adjustment_start_value { 25 }
      adjustment_end_value { 10 }
    end

    trait :fixed_amount do
      price_adjustment_type { :fixed }
      adjustment_value { 5_000 }
    end

    trait :for_service do
      association :service
    end
  end
end
