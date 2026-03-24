FactoryBot.define do
  factory :notification do
    association :business
    title { "Test notification" }
    body { "Test body" }
    notification_type { "subscription_expiry" }
    read { false }
  end
end
