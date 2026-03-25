FactoryBot.define do
  factory :employee_balance_adjustment do
    association :business
    association :employee
    association :performed_by_user, factory: :user
    amount { 10_000 }
    balance_before { 0 }
    balance_after { 10_000 }
    reason { "Manual adjustment" }
  end
end
