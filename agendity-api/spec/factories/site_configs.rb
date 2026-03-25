FactoryBot.define do
  factory :site_config do
    sequence(:key) { |n| "test_key_#{n}" }
    value { "test_value" }
    description { "A test config" }
  end
end
