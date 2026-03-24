FactoryBot.define do
  factory :subscription_payment_order do
    association :business
    association :plan
    amount { 49_900 }
    due_date { Date.current }
    period_start { Date.current }
    period_end { Date.current + 1.month }
    status { "pending" }
  end
end
