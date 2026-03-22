FactoryBot.define do
  factory :employee_payment do
    association :cash_register_close
    association :employee
    appointments_count { 5 }
    total_earned { 100_000 }
    commission_pct { 40 }
    commission_amount { 40_000 }
    pending_from_previous { 0 }
    total_owed { 40_000 }
    amount_paid { 40_000 }
    payment_method { :cash }
  end
end
