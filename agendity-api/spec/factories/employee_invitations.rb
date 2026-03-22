FactoryBot.define do
  factory :employee_invitation do
    association :employee
    association :business
    email { Faker::Internet.unique.email }
    # token and expires_at are set by model callbacks
  end
end
