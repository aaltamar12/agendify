FactoryBot.define do
  factory :subscription do
    association :business
    association :plan
    start_date { Date.current }
    end_date { 30.days.from_now }
    status { :active }
  end
end
