FactoryBot.define do
  factory :credit_transaction do
    association :credit_account
    amount { 5_000 }
    transaction_type { :cashback }
    description { "Test transaction" }
  end
end
