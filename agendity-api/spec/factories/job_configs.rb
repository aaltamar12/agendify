FactoryBot.define do
  factory :job_config do
    sequence(:job_class) { |n| "TestJob#{n}" }
    sequence(:name) { |n| "Test Job #{n}" }
    description { "A test job" }
    enabled { true }
  end
end
