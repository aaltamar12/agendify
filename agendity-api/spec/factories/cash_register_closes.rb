FactoryBot.define do
  factory :cash_register_close do
    association :business
    association :closed_by_user, factory: :user
    date { Date.current }
    status { :draft }
    total_revenue { 0 }
    total_appointments { 0 }
  end
end
