FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    price_monthly { 49_900 }
    max_employees { nil }
    max_services { nil }
    ai_features { false }
    ticket_digital { true }
    advanced_reports { true }
    brand_customization { true }
    featured_listing { false }
    priority_support { false }
  end
end
