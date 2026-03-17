FactoryBot.define do
  factory :payment do
    association :appointment
    payment_method { :transfer }
    amount { 25_000 }
    status { :pending }
  end
end
