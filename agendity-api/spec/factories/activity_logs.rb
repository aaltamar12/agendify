FactoryBot.define do
  factory :activity_log do
    association :business
    action { "appointment_created" }
    description { "New appointment created" }
    actor_type { "system" }
    metadata { {} }
  end
end
