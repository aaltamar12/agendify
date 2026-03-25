FactoryBot.define do
  factory :employee_service do
    association :employee
    association :service
  end
end
